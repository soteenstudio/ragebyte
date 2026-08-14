extends Node

@export var ingame: Node
@export var ui_controller: Node
@export var player: Node

signal is_map_loaded(map_id)

var map_folder1 = "res://scenes/maps/"
var map_folder2 = "res://scenes/maps/rooms/"

func _ready() -> void:
	MapSystem.auto_register_maps(map_folder1)
	MapSystem.auto_register_maps(map_folder2)

func _refresh_references():
	ingame = get_tree().get_first_node_in_group("ingame")
	ui_controller = get_tree().get_first_node_in_group("ui_controller")
	player = get_tree().get_first_node_in_group("player")

func register_node(node: Node, group: String) -> void:
	node.add_to_group(group)
	_refresh_references()

func load_maps(id: String, point_target: String) -> void:
	_refresh_references()
	
	if not Atomia.validate_bond(ingame) or not Atomia.validate_bond(ui_controller):
		push_error("Not found ingame or ui_controller node")
		return
	
	var margin_container = Atomia.secure_bond(ui_controller, "MarginContainer", MarginContainer)
	var loading_screen = Atomia.secure_bond(margin_container, "FlackLoadingScreen", Control)
	
	if Atomia.validate_bond(loading_screen):
		Atomia.react(loading_screen, "show")
		Atomia.set_isotope(loading_screen, "value", 0)
		Atomia.set_isotope(loading_screen, "text", tr("KEY_LOADING") + " 0%")
		Atomia.set_isotope(loading_screen, "debug_text", "Initializing map swap protocol...")
	
	var map_path = ""
	for map_data in KnifterDataManager.map_lists:
		if Atomia.get_isotope(map_data, "id") == id:
			map_path = Atomia.get_isotope(map_data, "path")
			break 
	
	if map_path == "" or not Atomia.react(ResourceLoader, "exists", [map_path]):
		Atomia.set_isotope(loading_screen, "debug_text", "Error: Map path invalid!")
		return

	# 2. PEMBERSIHAN TOTAL (Anti-Ghosting)
	Atomia.set_isotope(loading_screen, "debug_text", "Purging ActiveMaps from tree...")
	KnifterUtils.clear_all_maps()
	
	# Bersihkan point_lists lama biar gak bentrok sama yang baru
	KnifterDataManager.point_lists.clear()
	
	await Atomia.safe_await(self, "process_frame")
	await Atomia.safe_await(self, "physics_frame")

	# 3. REAL LOADING: Threaded
	ResourceLoader.load_threaded_request(map_path)
	Atomia.set_isotope(loading_screen, "debug_text", "ResourceLoader: Fetching data from disk...")
	
	var progress = []
	while true:
		var status = ResourceLoader.load_threaded_get_status(map_path, progress)
		var current_p = int(progress[0] * 100)
		
		Atomia.set_isotope(loading_screen, "value", current_p)
		Atomia.set_isotope(loading_screen, "text", tr("KEY_LOADING") + " " + str(current_p) + "%")
		Atomia.set_isotope(loading_screen, "debug_text", "Streaming: %s | Progress: %d%%" % [map_path.get_file(), current_p])
		
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			break 
		elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			Atomia.set_isotope(loading_screen, "debug_text", "FATAL ERROR: Map data corrupted!")
			return
		await Atomia.safe_await(self, "process_frame")

	# 4. DOUBLE CHECK
	if get_tree().get_nodes_in_group("ActiveMaps").size() > 0:
		KnifterUtils.clear_all_maps()
		await Atomia.safe_await(self, "process_frame")

	# 5. INSTANTIATE & ADD CHILD
	Atomia.set_isotope(loading_screen, "debug_text", "Finalizing: Building world environment...")
	var map_resource = ResourceLoader.load_threaded_get(map_path)
	var new_map = map_resource.instantiate()
	
	new_map.add_to_group("ActiveMaps")
	new_map.name = "Level_Map_" + str(id)
	#new_map.scale = Vector2(6.3, 6.3)
	
	ingame.add_child(new_map)
	
	# --- MODIF: TUNGGU MAP BARU SELESAI _READY & DAFTARIN POINT ---
	# Kita tunggu 2 frame biar semua node anak di map baru sempet panggil _add_point()
	await Atomia.safe_await(self, "process_frame")
	await Atomia.safe_await(self, "physics_frame")
	
	# BARU CARI POINT-NYA DI SINI (Setelah list terisi data baru)
	var point_index = KnifterDataManager.point_lists.find_custom(func(item): return item.id == point_target)
	
	if point_index != -1 and player:
		var target_pos = KnifterDataManager.point_lists[point_index].pos
		player.set_deferred("global_position", target_pos)
	else:
		push_error("Clay! Point '" + point_target + "' gak ketemu di map baru!")
	# --- END MODIF ---

	# 6. FINAL SYNC
	Atomia.set_isotope(loading_screen, "value", 100)
	Atomia.set_isotope(loading_screen, "text", "Loading... 100%")
	Atomia.set_isotope(loading_screen, "debug_text", "Deployment successful. Re-engaging player...")
	
	if await Atomia.safe_delay(loading_screen, 0.5): Atomia.react(loading_screen, "hide")
	
	is_map_loaded.emit(id)
