extends HumPlaEngine.BTNode

func tick(_delta) -> int:
	if npc.is_auto_moving: return HumPlaEngine.BTStatus.FAILURE
	npc.velocity = npc.velocity.lerp(Vector2.ZERO, npc.acceleration * _delta)
	npc.npc_anim.anim_state.travel("idle")
	npc.npc_data.idle_timer -= _delta
	if npc.npc_data.idle_timer <= 0:
		npc.pick_new_random_target()
		return HumPlaEngine.BTStatus.SUCCESS
	return HumPlaEngine.BTStatus.RUNNING
