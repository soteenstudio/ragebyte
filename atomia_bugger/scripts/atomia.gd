## [code]Atomia Bugger[/code]
## - Middleware that is tasked with being the last line of defense when a crash or force close occurs.

extends Node
class_name Atomia

enum Reaction { IGNORE, LOG, RECOVER, FATAL }

func _ready() -> void:
	print("[Atomia] Nucleus is stable. Defense system active.")

## Fungsi Utama: Reaksi Kimia (Eksekusi Code Aman)
static func react(caller: Object, method_name: StringName, args: Array = [], fallback_val = null):
	if not caller:
		_report("Caller is Null! Reaction aborted.", Reaction.LOG)
		return fallback_val
		
	if not caller.has_method(method_name):
		_report("Method '%s' not found in %s" % [method_name, caller.name], Reaction.LOG)
		return fallback_val

	# Eksekusi dengan pengaman
	var result = caller.callv(method_name, args)
	
	if result == null and fallback_val != null:
		return fallback_val
		
	return result

## Jaga-jaga buat Node yang sering ilang (Anti-Ghosting)
static func validate_bond(node: Node) -> bool:
	if is_instance_valid(node) and node.is_inside_tree():
		return true
	return false

static func _report(msg: String, type: Reaction):
	var prefix = "[Atomia Bugger]"
	match type:
		Reaction.LOG: print_rich("[color=yellow]%s LOG: %s[/color]" % [prefix, msg])
		Reaction.RECOVER: print_rich("[color=cyan]%s RECOVERY: %s[/color]" % [prefix, msg])
		Reaction.FATAL: push_error("%s FATAL: %s" % [prefix, msg])

# Di Atomia.gd (Autoload)

## Cek apakah kumpulan node (Molekul) sehat semua
static func check_stability(nodes: Array) -> bool:
	for n in nodes:
		if not validate_bond(n):
			_report("Instabilitas terdeteksi pada node: " + str(n), Reaction.RECOVER)
			return false
	return true

## Bersihkan ikatan yang rusak (Anti-Memory Leak)
static func stabilize_tree():
	# Contoh: Otomatis beresin node yang stuck di orphan string
	# (Bisa ditambahin logic pembersihan sesuai kebutuhan engine lo)
	pass

# Di dalam atomia.gd (Autoload)

## Versi super aman dari get_node_or_null
static func secure_bond(parent: Node, path: String, expected_type: Variant) -> Node:
	# 1. Cek apakah parent-nya sendiri valid
	if not is_instance_valid(parent):
		_report("Gagal nyari '%s' karena Parent-nya udah jadi abu!" % path, Reaction.RECOVER)
		return null
	
	var target = parent.get_node_or_null(path)
	
	# 2. Cek apakah targetnya beneran ada
	if not target:
		_report("Node di path '%s' emang gak ada, Clay!" % path, Reaction.LOG)
		return null
		
	# 3. Cek apakah targetnya 'Zombie' (lagi proses dihapus)
	if target.is_queued_for_deletion():
		_report("Node '%s' terdeteksi Zombie! Lagi proses pemusnahan." % path, Reaction.RECOVER)
		return null
		
	# 4. Cek Tipe Data (Anti-Salah Alamat)
	if expected_type != null:
		if not is_instance_of(target, expected_type):
			_report("Node '%s' ketemu, tapi tipenya bukan %s!" % [path, expected_type], Reaction.FATAL)
			return null

	return target

## Ambil 1 nilai secara aman (Support Object/Node & Dictionary)
static func get_isotope(source: Variant, property_name: String, fallback_val = null):
	# 1. Cek Dasar: Kalau null ya balikkan fallback
	if source == null:
		return fallback_val
	
	# 2. Kasus: Dictionary (pake bracket akses [] atau .has())
	if typeof(source) == TYPE_DICTIONARY:
		if source.has(property_name):
			return source[property_name]
		return fallback_val
		
	# 3. Kasus: Object/Node (pake .get() dan is_instance_valid)
	if typeof(source) == TYPE_OBJECT:
		if is_instance_valid(source):
			if property_name in source:
				return source.get(property_name)
			_report("Property '%s' gak ada di Object %s" % [property_name, source], Reaction.LOG)
		else:
			_report("Gagal ambil '%s', Object udah jadi abu!" % property_name, Reaction.LOG)
			
	return fallback_val

## Ubah 1 nilai secara aman (Support Object/Node & Dictionary)
static func set_isotope(target: Variant, property_name: String, new_value: Variant) -> bool:
	if target == null:
		return false
		
	# 1. Kasus: Dictionary
	if typeof(target) == TYPE_DICTIONARY:
		target[property_name] = new_value
		return true
		
	# 2. Kasus: Object/Node
	if typeof(target) == TYPE_OBJECT:
		if is_instance_valid(target):
			if property_name in target:
				target.set(property_name, new_value)
				return true
			_report("Gagal set '%s', property gak ada di %s" % [property_name, target], Reaction.LOG)
		else:
			_report("Gagal set '%s', Object invalid!" % property_name, Reaction.RECOVER)
			
	return false

## [MASS REACTION] Ambil nilai dari banyak objek sekaligus
static func get_isotopes(sources: Variant, property_name: String, fallback_val = null) -> Array:
	# 1. Cek apakah sources itu beneran Array
	if typeof(sources) != TYPE_ARRAY:
		_report("get_isotopes gagal: Sources bukan Array! (Tipe: %d)" % typeof(sources), Reaction.LOG)
		return []

	var results = []
	for source in sources:
		results.append(get_isotope(source, property_name, fallback_val))
	return results

## [MASS REACTION] Set nilai ke banyak objek sekaligus
static func set_isotopes(targets: Variant, property_name: String, new_value: Variant) -> bool:
	# 1. Cek apakah targets itu beneran Array
	if typeof(targets) != TYPE_ARRAY:
		_report("set_isotopes gagal: Targets bukan Array!", Reaction.LOG)
		return false
	
	# 2. Cek kalau Array-nya kosong (biar gak mubazir)
	if targets.is_empty():
		return true # Teknisnya gak ada yang gagal, jadi true aja
		
	var all_success = true
	for target in targets:
		# Kita pake 'success' buat mantau status tiap atom
		var success = set_isotope(target, property_name, new_value)
		if not success:
			all_success = false
			
	return all_success

## Await yang aman dari 'Orphan Script'. 
## Bakal return FALSE kalau objeknya keburu ancur pas lagi nunggu.
static func safe_await(caller: Node, signal_name: String = "process_frame") -> bool:
	if not validate_bond(caller):
		return false
	
	# Kita nunggu signal-nya
	if signal_name == "process_frame":
		await KnifterUtils.get_tree_safely().process_frame
	elif signal_name == "physics_frame":
		await KnifterUtils.get_tree_safely().physics_frame
	else:
		await caller.get_tree().create_timer(0.01).timeout # Default short wait

	# Setelah nunggu, CEK LAGI! Apakah caller masih idup?
	if not validate_bond(caller):
		_report("SafeAwait: Objek keburu musnah pas lagi nunggu!", Reaction.RECOVER)
		return false
		
	return true

static func safe_delay(caller: Node, duration: float) -> bool:
	await KnifterUtils.get_tree_safely().create_timer(duration).timeout
	return validate_bond(caller)
