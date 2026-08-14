@tool
extends EditorPlugin

func _enable_plugin() -> void:
	add_autoload_singleton("KnifterCore", "scripts/global.gd")

func _disable_plugin() -> void:
	remove_autoload_singleton("KnifterCore")

func _enter_tree() -> void:
	add_custom_type(
		"NavigationMap",
		"Node2D",
		preload("nodes/NavigationMap.gd"),
		preload("icons/navigation_map.png")
	)
	add_custom_type(
		"NavigationPortal",
		"Area2D",
		preload("nodes/NavigationPortal.gd"),
		preload("icons/navigation_portal.png")
	)
	add_custom_type(
		"NavigationPoint",
		"Area2D",
		preload("nodes/NavigationPoint.gd"),
		preload("icons/navigation_point.png")
	)

func _exit_tree() -> void:
	remove_custom_type("NavigationMap")
	remove_custom_type("NavigationPortal")
	remove_custom_type("NavigationPoint")
