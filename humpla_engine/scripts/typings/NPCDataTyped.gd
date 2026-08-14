extends RefCounted
class_name NPCDataTyped

const TRUST_THRESHOLD: float = 100.0
var friendlines_level = randi_range(0, 100)

var known_stalkers: Dictionary = {}
var is_panicking: bool = false
var panic_timer: float = 0.0

var forbidden_zones: Array[Dictionary] = [] 
var target_position: Vector2 = Vector2.ZERO
var idle_timer: float = 0.0
var last_global_pos: Vector2 = Vector2.ZERO
var stuck_check_timer: float = 0.0

var ray_center: RayCast2D 
var ray_left: RayCast2D 
var ray_right: RayCast2D 
var notifier: VisibleOnScreenNotifier2D
var octa_rays: Array[RayCast2D] = []

const OBSTACLE_THRESHOLD: float = 55.0 
const TARGET_REACHED_THRESHOLD: float = 15.0
