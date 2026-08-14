@tool
extends ColorRect
class_name VisualShadow

func _ready() -> void:
	# 1. Bikin Resource Shader-nya dulu
	var new_shader = Shader.new()
	new_shader.code = """
shader_type canvas_item;

// Tambahkan ini biar shader tau kita mau ambil jeroan renderer
render_mode unshaded; 

global uniform vec2 sun_offset;
global uniform float shadow_alpha;

// Tambahkan hint_screen_texture
uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
	COLOR = texture(screen_tex, SCREEN_UV);
}
	"""
	
	# 2. Masukin Shader ke Material
	var new_material = ShaderMaterial.new()
	new_material.shader = new_shader
	
	# 3. Pasang ke ColorRect
	self.material = new_material
