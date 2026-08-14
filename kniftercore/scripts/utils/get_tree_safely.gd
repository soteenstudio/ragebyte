extends Node

static func get_tree_safely() -> SceneTree:
	return Engine.get_main_loop() as SceneTree
