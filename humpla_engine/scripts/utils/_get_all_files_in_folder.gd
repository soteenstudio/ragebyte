extends Node

static func _get_all_files_in_folder(path: String) -> Array[String]:
	var found_files: Array[String] = []
	var dir = DirAccess.open(path)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				found_files.append(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	return found_files
