extends Node
class_name MapSystem

static func auto_register_maps(map_folder: StringName):
	var dir = DirAccess.open(map_folder)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tscn"):
				var map_id = file_name.get_basename() 
				var full_path = map_folder + file_name
				
				add_map(map_id, full_path)
				print("[KnifterCore] Auto-registered: ", map_id, " -> ", full_path)
			
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		push_error("Clay! Folder maps gak ketemu di: ", map_folder)

static func add_map(id_value: String, path_value: String) -> void:
	var new_data = MapTyped.new()
	new_data.id = id_value
	new_data.path = path_value
	KnifterDataManager.map_lists.push_back(new_data)

static func add_point(id_value: String, position: Vector2) -> void:
	if KnifterDataManager.point_lists.size() > KnifterDataManager.point_max_limit:
		KnifterDataManager.point_lists.resize(KnifterDataManager.point_max_limit)
	
	var new_data = PointTyped.new()
	new_data.id = id_value
	new_data.pos = position
	KnifterDataManager.point_lists.push_back(new_data)
