extends Node

const MIN_LIMIT = 150
const MAX_LIMIT = 8000
const LIMIT_PER_CORE = 80
const LIMIT_PER_GB_RAM = 128

static func get_dynamic_limit() -> int:
	var cpu_cores = OS.get_processor_count()
	var mem_info = OS.get_memory_info()
	
	var total_ram_gb = mem_info["physical"] / 1024.0 / 1024.0 / 1024.0
	
	var available_ram_gb = mem_info["available"] / 1024.0 / 1024.0 / 1024.0
	
	var base_calc = (cpu_cores * LIMIT_PER_CORE) + (total_ram_gb * LIMIT_PER_GB_RAM)
	
	var ram_ratio = available_ram_gb / total_ram_gb
	var usage_multiplier = 1.0
	
	if ram_ratio < 0.15:
		usage_multiplier = 0.4
	elif ram_ratio < 0.3:
		usage_multiplier = 0.7
		
	var final_limit = int(base_calc * usage_multiplier)
	
	return clampi(final_limit, MIN_LIMIT, MAX_LIMIT)
