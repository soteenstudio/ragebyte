extends Node

# --- PHYSICS CONFIG ---
# Semakin tinggi, semakin presisi tapi makin beban CPU (Low-level Substepping)
const PHYSICS_SUBSTEPS = 4
# Faktor inersia (Makin gede makin licin/berbobot)
const DEFAULT_INERTIA = 0.15 
# Kekuatan gesekan permukaan
const FRICTION_MULTIPLIER = 0.85

func _ready() -> void:
	Engine.physics_ticks_per_second = 60 # Standar, jangan terlalu tinggi buat hp kentang
	Engine.max_physics_steps_per_frame = 2 # Batasi biar gak "spiral of death"

func _physics_process(delta: float) -> void:
	_inject_procedural_physics(delta)

func _inject_procedural_physics(delta: float) -> void:
	var bodies = get_tree().get_nodes_in_group("physics_aware")
	
	for body in bodies:
		if is_instance_valid(body) and body is CharacterBody2D:
			if body.velocity.length_squared() < 0.01:
				continue 
			
			_apply_topdown_friction(body, delta)
			_apply_substep_logic(body, delta)

func _apply_substep_logic(body: CharacterBody2D, delta: float) -> void:
	# Trik: Kita pecah satu frame fisika jadi beberapa sub-langkah
	# Ini bikin collision response gak "nyangkut" di tembok tipis
	var substep_delta = delta / PHYSICS_SUBSTEPS
	
	for i in range(PHYSICS_SUBSTEPS):
		# Kita cuma "memperhalus" velocity sebelum move_and_slide dipanggil di script asli
		if body.velocity.length() > 0.1:
			# Tambahin inersia buatan biar stop-nya gak mendadak (Top-down feel)
			body.velocity = body.velocity.lerp(Vector2.ZERO, DEFAULT_INERTIA * substep_delta)

func _apply_topdown_friction(body: CharacterBody2D, delta: float) -> void:
	# 1. KONTROL VELOCITY (Gesekan Permukaan)
	# Rumus kenceng: velocity * (1 - (friction * delta))
	# Ini jauh lebih stabil di FPS rendah dibanding lerp manual
	body.velocity *= (1.0 - (FRICTION_MULTIPLIER * delta))

	# 2. VISUAL LEAN (Opsional, lo bisa hapus kalau masih kerasa lag)
	var main_sprite = body.get_node_or_null("Sprite2D")
	if main_sprite:
		var turn_velocity = body.velocity.x * 0.002
		main_sprite.rotation = lerp_angle(main_sprite.rotation, turn_velocity, 0.1)

func apply_impulse_to_body(body: CharacterBody2D, force: Vector2):
	var rid = body.get_rid()
	var current_vel = body.velocity
	PhysicsServer2D.body_set_state(rid, PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY, current_vel + force)
