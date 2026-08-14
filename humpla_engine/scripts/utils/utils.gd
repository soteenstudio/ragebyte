extends Node
class_name HumPlaUtils

static var _get_all_files_in_folder_call = preload("res://addons/humpla_engine/scripts/utils/_get_all_files_in_folder.gd")._get_all_files_in_folder
static var random_appearance_call = preload("res://addons/humpla_engine/scripts/utils/randomize_appearance.gd").randomize_appearance
static var start_random_blink_call = preload("res://addons/humpla_engine/scripts/utils/start_random_blink.gd").start_random_blink

static func _get_all_files_in_folder(path: String) -> Array[String]:
	return _get_all_files_in_folder_call.call(path)

static func randomize_appearance(base_path: String, sprite: NPCTyped) -> void:
	random_appearance_call.call(base_path, sprite)

static func start_random_blink(blink_timer: Timer) -> void:
	start_random_blink_call.call(blink_timer)
