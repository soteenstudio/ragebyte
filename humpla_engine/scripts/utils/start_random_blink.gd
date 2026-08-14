extends Node

static func start_random_blink(blink_timer: Timer):
	if blink_timer:
		blink_timer.stop()
		blink_timer.wait_time = randf_range(3.0, 6.0)
		blink_timer.start()
