extends HumPlaEngine.BTNode

func tick(_delta) -> int:
	if not npc.is_auto_moving: return HumPlaEngine.BTStatus.FAILURE
	
	var dist = npc.global_position.distance_to(npc.npc_data.target_position)
	if dist < npc.npc_data.TARGET_REACHED_THRESHOLD:
		npc.stop_and_idle(randf_range(3.0, 6.0))
		return HumPlaEngine.BTStatus.SUCCESS

	# === Stuck Detection ===
	npc.npc_data.stuck_check_timer += _delta
	if npc.npc_data.stuck_check_timer > 2.0:
		if npc.global_position.distance_to(npc.npc_data.last_global_pos) < 5.0:
			npc.record_obstacle(npc.global_position + npc.velocity.normalized() * 35)
			npc.stop_and_idle(1.5)
			return HumPlaEngine.BTStatus.FAILURE
		npc.npc_data.stuck_check_timer = 0.0
		npc.npc_data.last_global_pos = npc.global_position

	# === Steering Logic ===
	var target_dir = npc.global_position.direction_to(npc.npc_data.target_position)
	npc.velocity = npc.velocity.lerp(target_dir * npc.current_speed, npc.acceleration * _delta)
	
	# === Octa-Raycast Collision Logic ===
	# Gak perlu rotate ray lagi, kita cuma perlu cek mana yang nabrak
	for ray in npc.npc_data.octa_rays:
		if ray.is_colliding():
			# Kalau nabrak sesuatu, catat posisinya dan berhenti
			var collision_pt = ray.get_collision_point()
			npc.record_obstacle(collision_pt)
			npc.stop_and_idle(2.0)
			return HumPlaEngine.BTStatus.FAILURE

	# === Visual & Animation ===
	npc.npc_anim.anim_state.travel("walk")
	if abs(npc.velocity.x) > 0.5:
		npc.npc_anim.sprites_container.scale.x = 1 if npc.velocity.x > 0 else -1
		
	return HumPlaEngine.BTStatus.RUNNING
