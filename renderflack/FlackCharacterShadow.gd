class_name FlackCharacterShadow
extends CharacterBody2D

# --- INJECTION LOGIC ---
## Inject script logic player di sini (Drag & Drop file .gd ke sini)
@export var brain_logic: Script:
	set(value):
		brain_logic = value
		if value:
			# Pasang script eksternal ke objek ini secara dinamis
			set_script(value)

# --- ENGINE TECH SETTINGS ---
## Node yang nampung semua bagian sprite karakter (misal: "SpritesContainer")
@export var sprite_container_path: NodePath
@export_group("Sun Tech")
@export_range(-2.0, 2.0) var sun_offset: float = 0.0
@export_range(0.0, 1.0) var shadow_opacity: float = 0.4
@export var shadow_color: Color = Color(0.0, 0.0, 0.1, 0.5)

@export_group("Shadow Geometry")
@export var shadow_scale: Vector2 = Vector2(1.1, 0.3)
## Titik tumpu bayangan (biasanya di kaki karakter)
@export var shadow_origin_offset: Vector2 = Vector2(0, 0)

# --- LOW LEVEL HANDLES (GPU PIPELINE) ---
var shadow_rid: RID
var material_rid: RID
var shader_rid: RID
var container_node: Node2D

func _enter_tree() -> void:
	_init_gpu_pipeline()

func _ready() -> void:
	if sprite_container_path:
		container_node = get_node(sprite_container_path)
	else:
		container_node = get_node_or_null("Sprites")

func _init_gpu_pipeline():
	if shadow_rid.is_valid(): return
	
	shadow_rid = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_parent(shadow_rid, get_canvas_item())
	
	RenderingServer.canvas_item_set_draw_index(shadow_rid, -1)
	RenderingServer.canvas_item_set_z_index(shadow_rid, -1)
	
	shader_rid = RenderingServer.shader_create()
	var shader_code = """
	shader_type canvas_item;
	render_mode blend_mix;
	uniform vec4 shadow_col : source_color;
	
	void fragment() {
		vec4 tex = texture(TEXTURE, UV);
		COLOR = vec4(shadow_col.rgb, tex.a * shadow_col.a);
	}
	"""
	RenderingServer.shader_set_code(shader_rid, shader_code)
	
	material_rid = RenderingServer.material_create()
	RenderingServer.material_set_shader(material_rid, shader_rid)
	RenderingServer.canvas_item_set_material(shadow_rid, material_rid)

func _exit_tree():
	if shadow_rid.is_valid():
		RenderingServer.free_rid(shadow_rid)
	if material_rid.is_valid():
		RenderingServer.free_rid(material_rid)
	if shader_rid.is_valid():
		RenderingServer.free_rid(shader_rid)

func _process(_delta: float) -> void:
	if not shadow_rid.is_valid() or not container_node: return
	
	RenderingServer.canvas_item_clear(shadow_rid)
	
	var final_col = shadow_color
	final_col.a = shadow_opacity
	RenderingServer.material_set_param(material_rid, "shadow_col", final_col)
	
	for child in container_node.get_children():
		if child is Sprite2D and child.visible and child.texture:
			_draw_shadow_part(child)

func _physics_process(_delta: float) -> void:
	pass

func _draw_shadow_part(s: Sprite2D):
	var tex_rid = s.texture.get_rid()
	var xform = Transform2D()
	
	xform = xform.translated(s.position + shadow_origin_offset)
	xform.x.y = sun_offset 
	xform = xform.scaled(shadow_scale * s.scale)
	xform = xform.rotated_local(s.rotation)
	
	RenderingServer.canvas_item_set_transform(shadow_rid, xform)
	
	var drawing_rect = s.get_rect()
	drawing_rect.position = s.get_rect().position 
	
	RenderingServer.canvas_item_add_texture_rect(shadow_rid, drawing_rect, tex_rid, false)
