extends Node2D
class_name VisualSun

@export var shadow_opacity: float = 0.4
@export var sun_direction: Vector2 = Vector2(0.5, 0.3) # x buat miring, y buat tinggi

var shadow_material: RID

func _ready():
	if Engine.is_editor_hint(): return
	
	# 1. Bikin Shader Material sekali aja buat dipake semua shadow
	var shader_rid = RenderingServer.shader_create()
	var code = """
	shader_type canvas_item;
	render_mode unshaded;
	uniform float alpha : hint_range(0.0, 1.0);
	void fragment() {
		vec4 col = texture(TEXTURE, UV);
		if (col.a > 0.1) {
			COLOR = vec4(0.0, 0.0, 0.0, alpha);
		} else {
			discard;
		}
	}
	"""
	RenderingServer.shader_set_code(shader_rid, code)
	shadow_material = RenderingServer.material_create()
	RenderingServer.material_set_shader(shadow_material, shader_rid)

func apply_shadow_to_node(target_node: CanvasItem):
	# Fungsi ini buat daftarin siapa aja yang mau dikasih bayangan
	# Lu bisa panggil ini di script player atau musuh
	var shadow_item = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_parent(shadow_item, target_node.get_canvas_item())
	
	# Set urutan biar di bawah bapaknya
	RenderingServer.canvas_item_set_draw_index(shadow_item, -1)
	RenderingServer.canvas_item_set_material(shadow_item, shadow_material)
	
	# Trick: Kita gak perlu gambar ulang, kita suruh server pake texture target
	# Tapi karena kita mau setup transform global, mending pake loop di _process

func _process(_delta):
	# Kita update parameter alpha global (kalo lu pake global uniform)
	# Atau manual per material
	RenderingServer.material_set_param(shadow_material, "alpha", shadow_opacity)
	
	# Logic Skew Matrix
	var skew_m = Transform2D()
	
	# KUNCI GEPREK:
	# Axis X tetep (1, 0)
	# Axis Y kita miringin (sun_direction.x) dan kita pendekin (sun_direction.y)
	skew_m.x = Vector2(1.0, 0.0)
	skew_m.y = Vector2(sun_direction.x, sun_direction.y) 
	skew_m.origin = Vector2(0, 0) # Nempel di kaki

	# Kalo lu mau otomatis ke semua anak Node ini:
	for child in get_children():
		if child is Sprite2D:
			# Manipulasi transform di level CanvasItem biar gepeng
			RenderingServer.canvas_item_set_transform(child.get_canvas_item(), skew_m)
