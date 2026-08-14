extends Node

static func clear_all_maps() -> void:
	var old_maps = KnifterUtils.get_tree_safely().get_nodes_in_group("ActiveMaps")
	for map in old_maps:
		Atomia.react(map, "remove_from_group", ["ActiveMaps"])
		
		if map.get_parent():
			map.get_parent().remove_child(map)
		
		Atomia.react(map, "queue_free")
