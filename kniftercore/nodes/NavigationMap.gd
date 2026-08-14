## [KnifterCore]
## NavigationMap is a node that is used as a container for a map.
extends Node2D
class_name NavigationMap

func _ready() -> void:
	self.add_to_group("rooms")
	self.z_as_relative = false
	self.y_sort_enabled = true
	
	self.add_to_group("ActiveMaps")
