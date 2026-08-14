extends HumPlaEngine.BTNode

var back_off_timer: float = 0.0
var is_backing_off: bool = false

func tick(_delta) -> int:
	# Cari player (Ganti "Player" sesuai nama grup/node player lu)
	var player = npc.get_tree().get_first_node_in_group("player")
	if not player: return HumPlaEngine.BTStatus.FAILURE
	
	var dist_to_player = npc.global_position.distance_to(player.global_position)
	
	# 1. Cek apakah player penguntit lama atau lagi deket banget
	if dist_to_player < npc.stalker_detection_radius:
		if not npc.is_bestie:
			if not is_backing_off and not npc.npc_data.is_panicking:
				# Noleh ke player
				npc.npc_anim.sprites_container.scale.x = 1 if (player.global_position.x > npc.global_position.x) else -1
				
				# Keputusan: Mundur dulu pelan atau langsung lari
				if randf() > 0.4: # 60% chance mundur dulu
					is_backing_off = true
					back_off_timer = 1.5
					print("NPC: Eh? Siapa lu? Jangan deket-deket!")
				else:
					HumPlaActions.start_panic_run(npc)
				return HumPlaEngine.BTStatus.RUNNING

	# 2. Logic Jalan Mundur
	if is_backing_off:
		back_off_timer -= _delta
		var dir_away = player.global_position.direction_to(npc.global_position)
		npc.velocity = npc.velocity.lerp(dir_away * (npc.speed_normal * 0.4), npc.acceleration * _delta)
		npc.npc_anim.anim_state.travel("walk") # Tetap pake anim walk tapi speed pelan
		
		if back_off_timer <= 0 or dist_to_player < 60: # Kalau kejauhan atau malah makin deket
			is_backing_off = false
			HumPlaActions.start_panic_run(npc)
		return HumPlaEngine.BTStatus.RUNNING

	# 3. Logic Lari Ketakutan (Panic)
	if npc.npc_data.is_panicking:
		npc.npc_data.panic_timer -= _delta
		npc.current_speed = npc.speed_panic
		if npc.npc_data.panic_timer <= 0:
			npc.npc_data.is_panicking = false
			npc.stop_and_idle(2.0)
			return HumPlaEngine.BTStatus.SUCCESS
		return HumPlaEngine.BTStatus.FAILURE # Biar lanjut ke pergerakan target panic
		
	return HumPlaEngine.BTStatus.FAILURE
