## [KnifterCore]
## NavigationPortal is a node used to navigate scene changes in the game.
@tool
extends Area2D
class_name NavigationPortal

## [code]portal_path[/code] is a property where you enter the ID of the scene.
@export var portal_path: String = "map"
## [code]point_target[/code] is a property that contains the ID of a specific target point within the scene. 
@export var point_target: String = "target"

func _ready() -> void:
	if get_child_count() > 0:
		for child in get_children():
			child.queue_free()
	
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	
	shape.size = Vector2(32.0, 32.0)
	collision.shape = shape
	
	self.add_child(collision)
	
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	if Engine.is_editor_hint():
		return
	
	var parent = get_parent()
	
	if area.get_parent().name == "Player":
		KnifterCore.call_deferred("load_maps", portal_path, point_target)
