@tool

extends CharacterBody2D
class_name HumPlaEngine

@export_group("Movement")
@export var speed_normal: float = 160.0 
@export var speed_tired: float = 70.0 
@export var speed_panic: float = 280.0
@export var wander_radius: float = 450.0 
@export var acceleration: float = 8.0 

@export_group("Stats System")
@export var max_hunger: float = 100.0
@export var max_stamina: float = 100.0
@export var stamina_regen_rate: float = 4.0
@export var hunger_drain_walk: float = 0.15
@export var hunger_to_stamina_cost: float = 1.8

@export_group("AI Logic")
@export var obstacle_detection_range: float = 70.0
@export var stalker_detection_radius: float = 120.0
@export var handshake_detection_radius: float = 200.0
@export var memory_limit: int = 30
@export var memory_forget_time: float = 20.0
@export var external_bt_nodes: Array[Script] = []

@export_group("NPC")
@export_subgroup("Settings")
@export var editor_mode = true
@export_subgroup("Status")
@export var is_faint: bool = false
@export var is_auto_moving: bool = false
@export var player_unconfortable = false
@export var is_bestie: bool = false
@export_enum("male", " female") var gender = "male"
@export_subgroup("Data")
@export var hunger: float = 100.0
@export var stamina: float = 100.0
@export var current_speed: float = 160.0
@export var uncomfortable_timer: float = 0.0
@export var last_player_dist: float = 0.0
@export var trust_level: float = 0.0

@export_group("Animation")

@export_group("Random Appearance")
@export var base_path: String = "res://sprites/npc/male/"

var sprites: NPCTyped
var npc_data: NPCDataTyped
var npc_anim: NPCAnimationTyped
var bt_root: BTNode 

enum BTStatus { SUCCESS, FAILURE, RUNNING }

class BTNode:
	var npc: CharacterBody2D
	func _init(_npc): npc = _npc
	func tick(_delta: float) -> int: return BTStatus.SUCCESS

class BTSelector extends BTNode:
	var children: Array = []
	func _init(_npc, _children): super(_npc); children = _children
	func tick(_delta: float) -> int:
		for child in children:
			var status = child.tick(_delta)
			if status != BTStatus.FAILURE: return status
		return BTStatus.FAILURE

func _ready():
	if editor_mode and Engine.is_editor_hint():
		return
	
	sprites = NPCTyped.new()
	npc_data = NPCDataTyped.new()
	npc_anim = NPCAnimationTyped.new()
	
	sprites.sprite_body = $SpritesContainer/body
	sprites.sprite_head = $SpritesContainer/head
	sprites.sprite_hair = $SpritesContainer/head/hair
	sprites.sprite_hand_near = $SpritesContainer/handNear
	sprites.sprite_hand_far = $SpritesContainer/handFar
	sprites.sprite_leg_near = $SpritesContainer/legNear
	sprites.sprite_leg_far = $SpritesContainer/legFar
	
	npc_anim.anim_tree = $AnimationTree
	npc_anim.anim_state = npc_anim.anim_tree.get("parameters/StateMachine/playback")
	npc_anim.sprites_container = $SpritesContainer
	npc_anim.blink_timer = $BlinkTimer
	
	gender = "male" if randi_range(0, 1) == 0 else "female"
	base_path = "res://sprites/npc/" + gender + "/"
	
	HumPlaUtils.randomize_appearance(base_path, sprites)
	
	var NodeIdlePlanning = load("res://addons/humpla_engine/scripts/node_idle_planning.gd")
	var NodeMoveToTarget = load("res://addons/humpla_engine/scripts/node_move_to_target.gd")
	var NodeHandshake = load("res://addons/humpla_engine/scripts/node_handshake.gd")
	var NodeStalkerReaction = load("res://addons/humpla_engine/scripts/node_stalker_reaction.gd")
	var NodeCheckFaint = load("res://addons/humpla_engine/scripts/node_check_faint.gd")
	
	_setup_rays()
	_create_notifier()
	npc_data.last_global_pos = global_position
	
	var bt_list = [
		NodeCheckFaint.new(self),
		NodeStalkerReaction.new(self)
	]
	
	for bt_script in external_bt_nodes:
		if bt_script:
			var instance = bt_script.new(self)
			bt_list.append(instance)
	
	bt_list.append(NodeHandshake.new(self))
	bt_list.append(NodeMoveToTarget.new(self))
	
	bt_list.append(NodeIdlePlanning.new(self))
	
	bt_root = BTSelector.new(self, bt_list)
	
	if npc_anim.blink_timer:
		if not npc_anim.blink_timer.timeout.is_connected(_on_blink_timer_timeout):
			npc_anim.blink_timer.timeout.connect(_on_blink_timer_timeout)
		HumPlaUtils.start_random_blink(npc_anim.blink_timer)
	
	KnifterCore.is_map_loaded.connect(_resetup)

func _physics_process(delta):
	if not bt_root:
		return
	
	_update_memory_timer(delta)
	_handle_status_logic(delta)
	bt_root.tick(delta)
	move_and_slide()
	
	if player_unconfortable:
		uncomfortable_timer += delta
		if uncomfortable_timer > 60.0:
			player_unconfortable = false
			uncomfortable_timer = 0.0
	
	var player = get_tree().get_first_node_in_group("player")
	if player and not npc_data.is_panicking and not player_unconfortable:
		var d = global_position.distance_to(player.global_position)
		if d < handshake_detection_radius + 50.0:
			trust_level += 2.0 * delta 
			if trust_level >= npc_data.TRUST_THRESHOLD:
				if not is_bestie:
					pass
				is_bestie = true

func _handle_status_logic(delta):
	if npc_data.is_panicking:
		current_speed = speed_panic
	else:
		current_speed = speed_tired if stamina < 20 else speed_normal
	
	var drain_mult = 3.0 if npc_data.is_panicking else 1.0
	
	if is_auto_moving:
		stamina -= 1.5 * delta * drain_mult
		hunger -= hunger_drain_walk * delta * drain_mult
	else:
		if stamina < max_stamina:
			stamina += stamina_regen_rate * delta
			if stamina < 30 and hunger > 20:
				var boost = hunger_to_stamina_cost * delta
				stamina += boost
				hunger -= boost * 1.2
	
	stamina = clamp(stamina, 0, max_stamina)
	hunger = clamp(hunger, 0, max_hunger)

func _setup_rays():
	var angle_step = TAU / 8
	
	for i in range(8):
		var angle = i * angle_step
		var direction = Vector2.RIGHT.rotated(angle) 
		var target_pos = direction * obstacle_detection_range
		
		var ray = _create_ray(target_pos)
		npc_data.octa_rays.append(ray)

func _create_ray(target_pos: Vector2) -> RayCast2D:
	var r = RayCast2D.new(); add_child(r); r.enabled = true
	r.add_exception(self); r.target_position = target_pos; r.position = Vector2(0, -5)
	return r

func _set_rays_enabled(is_on: bool):
	for ray in npc_data.octa_rays:
		if ray:
			ray.enabled = is_on

func _create_notifier():
	npc_data.notifier = VisibleOnScreenNotifier2D.new()
	npc_data.notifier.rect = Rect2(-30, -50, 60, 100)
	
	npc_data.notifier.screen_entered.connect(_on_npc_visible)
	npc_data.notifier.screen_exited.connect(_on_npc_invisible)
	
	add_child(npc_data.notifier)

func _on_npc_visible():
	if npc_anim.anim_tree: npc_anim.anim_tree.active = true
	_set_rays_enabled(true)
	set_physics_process(true)

func _on_npc_invisible():
	if npc_anim.anim_tree: npc_anim.anim_tree.active = false
	
	_set_rays_enabled(false)

func trigger_blackout():
	is_faint = true; is_auto_moving = false; npc_data.is_panicking = false
	velocity = Vector2.ZERO; npc_anim.anim_state.travel("faint")

func _handle_faint_recovery(delta):
	npc_data.idle_timer += delta
	if npc_data.idle_timer > 10.0:
		hunger = 30.0; is_faint = false; npc_anim.anim_state.travel("idle"); npc_data.idle_timer = 3.0

func pick_new_random_target():
	if stamina < 15: npc_data.idle_timer = 5.0; return
	var attempts = 0
	while attempts < 8:
		var offset = Vector2(randf_range(-wander_radius, wander_radius), randf_range(-wander_radius, wander_radius))
		var pt = global_position + offset
		if not _is_pos_forbidden(pt):
			npc_data.target_position = pt; is_auto_moving = true; npc_data.stuck_check_timer = 0.0; return
		attempts += 1
	npc_data.idle_timer = 2.0

func _is_pos_forbidden(pos: Vector2) -> bool:
	for zone in npc_data.forbidden_zones:
		if pos.distance_to(zone.pos) < npc_data.OBSTACLE_THRESHOLD: return true
	return false

func record_obstacle(pos: Vector2):
	if not _is_pos_forbidden(pos):
		npc_data.forbidden_zones.append({"pos": pos, "time": memory_forget_time})
		if npc_data.forbidden_zones.size() > memory_limit: npc_data.forbidden_zones.remove_at(0)

func _update_memory_timer(delta):
	for i in range(npc_data.forbidden_zones.size() - 1, -1, -1):
		npc_data.forbidden_zones[i].time -= delta
		if npc_data.forbidden_zones[i].time <= 0: npc_data.forbidden_zones.remove_at(i)

func stop_and_idle(duration: float):
	is_auto_moving = false; npc_data.is_panicking = false
	npc_data.idle_timer = duration; npc_data.stuck_check_timer = 0.0

func face_target(pos: Vector2):
	if npc_anim.sprites_container:
		npc_anim.sprites_container.scale.x = 1 if (pos.x > global_position.x) else -1

func is_any_obstacle_detected() -> bool:
	for ray in npc_data.octa_rays:
		if ray.is_colliding():
			return true
	return false

func get_avoidance_vector() -> Vector2:
	var avoid_vec = Vector2.ZERO
	for ray in npc_data.octa_rays:
		if ray.is_colliding():
			avoid_vec -= ray.target_position.normalized()
	return avoid_vec.normalized()

func _file_exists_on_all_platforms(full_path: String) -> bool:
	return FileAccess.file_exists(full_path) or FileAccess.file_exists(full_path + ".remap")

func _resetup(id: String):
	if id:
		stamina = 100
		hunger = 100
		gender = "male" if randi_range(0, 1) == 0 else "female"
		base_path = "res://sprites/npc/" + gender + "/"
		HumPlaUtils.randomize_appearance(base_path, sprites)

func _on_blink_timer_timeout():
	if npc_anim.anim_tree:
		npc_anim.anim_tree.set("parameters/OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	HumPlaUtils.start_random_blink(npc_anim.blink_timer)
