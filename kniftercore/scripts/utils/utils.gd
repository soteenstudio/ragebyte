extends Node
class_name KnifterUtils

static var get_dynamic_limit_call = preload("res://addons/kniftercore/scripts/utils/get_dynamic_limit.gd").get_dynamic_limit
static var clear_all_maps_call = preload("res://addons/kniftercore/scripts/utils/clear_all_maps.gd").clear_all_maps
static var get_tree_safely_call = preload("res://addons/kniftercore/scripts/utils/get_tree_safely.gd").get_tree_safely

static func get_dynamic_limit():
	return get_dynamic_limit_call.call()

static func clear_all_maps():
	clear_all_maps_call.call()

static func get_tree_safely() -> SceneTree:
	return get_tree_safely_call.call()
