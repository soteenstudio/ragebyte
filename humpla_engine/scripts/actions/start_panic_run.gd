extends Node

static func start_panic_run(npc):
	var player = KnifterUtils.get_tree_safely().get_first_node_in_group("player")
	if not player: return
	
	print("NPC: AAAAAA TOLOOONG!")
	npc.npc_data.is_panicking = true
	npc.npc_data.panic_timer = 4.0
	
	var escape_dir = player.global_position.direction_to(npc.global_position)
	npc.npc_data.target_position = npc.global_position + (escape_dir * 500)
	npc.is_auto_moving = true
	npc.trust_level -= 20.0
	npc.is_bestie = false if npc.trust_level < npc.npc_data.TRUST_THRESHOLD else true
	npc.trust_level = clamp(npc.trust_level, 0, npc.npc_data.TRUST_THRESHOLD)
