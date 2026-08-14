## [KnifterCore]
## NavigationPoint is a marker used to determine the destination where the player is placed when changing locations via [NavigationPortal].
@tool
extends Area2D
class_name NavigationPoint

## [code]id[/code] is a property used to determine the unique ID of a point.
@export var id: String = "00"

func _ready() -> void:
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	
	shape.size = Vector2(25, 25)
	collision.shape = shape
	
	self.add_child(collision)
	
	if not Engine.is_editor_hint():
		MapSystem.add_point(id, self.global_position)
