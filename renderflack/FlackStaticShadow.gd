class_name FlackStaticShadow
extends StaticBody2D

# --- ENGINE TECH SETTINGS (DO NOT CHANGE) ---
@export_group("Sun Tech")
@export_range(-2.0, 2.0) var sun_offset: float = 0.0
@export_range(0.0, 1.0) var shadow_opacity: float = 0.5
@export var shadow_color: Color = Color(0.05, 0.05, 0.1, 0.5)

@export_group("Shadow Geometry")
@export var shadow_scale: Vector2 = Vector2(1.2, 0.3)
@export_range(0.0, 1.0) var foot_pivot: float = 0.45

@export_group("Internal Occlusion")
## Bitmask untuk menentukan bayangan ini berinteraksi dengan layer apa (Low Level)
@export_flags_2d_render var visibility_layer_mask: int = 1
## Menentukan apakah bayangan ini dipotong oleh objek lain (Occlusion)
@export var enable_self_occlusion: bool = true

# --- LOW LEVEL HANDLES (GPU PIPELINE) ---
var shadow_rid: RID
var material_rid: RID
var shader_rid: RID
var child_sprites: Array[Sprite2D] = []

@onready var sprite = $Sprite2D
@onready var area = $Area2D

func _ready() -> void:
	area.connect("area_entered", _on_area_2d_body_entered)
	area.connect("area_exited", _on_area_2d_body_exited)

func _enter_tree():
	_init_gpu_pipeline()
	_refresh_child_cache()

func _init_gpu_pipeline():
	if shadow_rid.is_valid(): return
	
	# 1. Initialize Canvas Item
	shadow_rid = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_parent(shadow_rid, get_canvas_item())
	
	# --- TECH: MANUAL OCCLUSION HANDLING ---
	# Kita set draw index paling bawah biar gak numpuk di atas sprite aslinya
	RenderingServer.canvas_item_set_draw_index(shadow_rid, -1)
	RenderingServer.canvas_item_set_z_index(shadow_rid, -1)
	# Pasang visibility mask secara manual ke RenderingServer
	RenderingServer.canvas_item_set_visibility_layer(shadow_rid, visibility_layer_mask)
	
	# 2. Shader Advanced dengan Clip Logic
	shader_rid = RenderingServer.shader_create()
	var shader_code = """
	shader_type canvas_item;
	render_mode blend_mix;
	
	uniform vec4 shadow_col : source_color;
	uniform float skew_strength;
	uniform bool use_occlusion;
	
	void fragment() {
		vec4 tex = texture(TEXTURE, UV);
		
		// Softness math
		float softness = 1.0 - (abs(skew_strength) * 0.1 * UV.y);
		
		// Occlusion Clip: Jika UV koordinat bayangan keluar dari batas 'ground', potong.
		// Ini simulasi kalau bayangan jatuh ke area yang lebih rendah/tinggi
		float clip = 1.0;
		if (use_occlusion && UV.y < 0.1) {
			clip = smoothstep(0.0, 0.1, UV.y);
		}
		
		COLOR = vec4(shadow_col.rgb, tex.a * shadow_col.a * softness * clip);
	}
	"""
	RenderingServer.shader_set_code(shader_rid, shader_code)
	
	# 3. Create Material Handle
	material_rid = RenderingServer.material_create()
	RenderingServer.material_set_shader(material_rid, shader_rid)
	RenderingServer.canvas_item_set_material(shadow_rid, material_rid)

func _exit_tree():
	if shadow_rid.is_valid():
		RenderingServer.free_rid(shadow_rid)
		shadow_rid = RID() # Reset ke kosong
	# Lakukan hal yang sama buat material dan shader

func _refresh_child_cache():
	child_sprites.clear()
	for child in get_children():
		if child is Sprite2D:
			child_sprites.append(child)

func _process(_delta):
	if not shadow_rid.is_valid() or child_sprites.is_empty(): return
	
	# Re-sync visibility layer pas runtime kalau lo ubah di inspector
	RenderingServer.canvas_item_set_visibility_layer(shadow_rid, visibility_layer_mask)
	RenderingServer.canvas_item_clear(shadow_rid)
	
	# Push Uniforms
	var final_col = shadow_color
	final_col.a = shadow_opacity
	RenderingServer.material_set_param(material_rid, "shadow_col", final_col)
	RenderingServer.material_set_param(material_rid, "skew_strength", sun_offset)
	RenderingServer.material_set_param(material_rid, "use_occlusion", enable_self_occlusion)
	
	for sprite in child_sprites:
		if not is_instance_valid(sprite) or not sprite.visible or not sprite.texture:
			continue
			
		var tex_rid = sprite.texture.get_rid()
		var size = sprite.texture.get_size()
		
		# --- CORE MATRIX TRANSFORM ---
		var xform = Transform2D()
		
		# Position logic
		var foot_pos = sprite.position + Vector2(0, (size.y * foot_pivot) * sprite.scale.y)
		xform = xform.translated(foot_pos)
		
		# Skewing & Scaling
		xform.x.y = sun_offset
		xform = xform.scaled(shadow_scale)
		
		# Push to GPU
		RenderingServer.canvas_item_set_transform(shadow_rid, xform)
		
		# Draw call
		var draw_rect = Rect2(-size / 2, size)
		RenderingServer.canvas_item_add_texture_rect(shadow_rid, draw_rect, tex_rid, false)

func _on_area_2d_body_entered(body: Node2D) -> void:
	#sprite.z_index = 20
	# Cek apakah yang masuk itu Player (pake group atau name)
	if body.is_in_group("player"):
		# Bikin transparan (0.5 = 50% kelihatan)
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.5, 0.3)

func _on_area_2d_body_exited(body: Node2D) -> void:
	#sprite.z_index = 0
	if body.is_in_group("player"):
		# Balikin jadi solid (1.0 = 100% kelihatan)
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 1.0, 0.3)
