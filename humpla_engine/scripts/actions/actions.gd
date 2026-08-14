extends Node
class_name HumPlaActions

static var start_panic_run_call = preload("res://addons/humpla_engine/scripts/actions/start_panic_run.gd").start_panic_run

static func start_panic_run(npc) -> void:
	start_panic_run_call.call(npc)
