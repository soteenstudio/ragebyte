extends HumPlaEngine.BTNode

func tick(_delta) -> int:
	if npc.is_faint:
		npc._handle_faint_recovery(_delta)
		return HumPlaEngine.BTStatus.RUNNING
	if npc.hunger <= 0:
		npc.trigger_blackout()
		return HumPlaEngine.BTStatus.RUNNING
	return HumPlaEngine.BTStatus.FAILURE
