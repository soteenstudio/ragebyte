extends HumPlaEngine.BTNode

var is_approaching: bool = false

func tick(_delta):
	var player = npc.get_tree().get_first_node_in_group("player")
	if not player or npc.player_unconfortable or npc.npc_data.is_panicking: 
		is_approaching = false
		return HumPlaEngine.BTStatus.FAILURE
	
	if npc.npc_data.friendlines_level <= 50:
		return HumPlaEngine.BTStatus.FAILURE

	var dist = npc.global_position.distance_to(player.global_position)
	
	# 1. DETEKSI KABUR (The "Anti-Anyink" Logic)
	if is_approaching and npc.last_player_dist > 0:
		# Kalo jarak nambah pas lagi disamperin = PLAYER RISIH
		if dist > npc.last_player_dist + 1.2:
			if not npc.is_bestie:
				npc.player_unconfortable = true
				npc.uncomfortable_timer = 0.0 # Reset timer risih
				npc.last_player_dist = 0.0
				is_approaching = false
				npc.stop_and_idle(20.0) # DIEM DI TEMPAT 20 DETIK!
				print("NPC: Waduh kabur dia, gue nunggu sini aja dah...")
				return HumPlaEngine.BTStatus.FAILURE
			else:
				is_approaching = false
				npc.stop_and_idle(2.0)
				return HumPlaEngine.BTStatus.SUCCESS
	
	npc.last_player_dist = dist

	# 2. JARAK AMAN (Handshake Reach)
	if dist < npc.handshake_detection_radius:
		is_approaching = false # Udah nyampe, gak usah ngejar lagi
		npc.velocity = npc.velocity.lerp(Vector2.ZERO, npc.acceleration * _delta)
		npc.face_target(player.global_position)
		npc.npc_anim.anim_state.travel("idle")
		return HumPlaEngine.BTStatus.SUCCESS 

	# 3. KEPUTUSAN MAJU
	# Cuma maju kalo player deket tapi gak terlalu jauh (biar gak ngejar ke ujung map)
	if dist < 450.0:
		is_approaching = true
		var target_dir = npc.global_position.direction_to(player.global_position)
		npc.velocity = npc.velocity.lerp(target_dir * npc.speed_normal, npc.acceleration * _delta)
		npc.npc_anim.anim_state.travel("walk")
		if abs(npc.velocity.x) > 0.5:
			npc.npc_anim.sprites_container.scale.x = 1 if npc.velocity.x > 0 else -1
		return HumPlaEngine.BTStatus.RUNNING
	
	is_approaching = false
	return HumPlaEngine.BTStatus.FAILURE
