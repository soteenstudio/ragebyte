@tool
extends Control

@export_multiline var text: String = "Loading... 0%":
	set(v):
		text = v
		_update_ui()
@export_multiline var debug_text: String = "Ingerna":
	set(v):
		debug_text = v
		_update_ui()
@export_range(0, 100) var value = 0.0:
	set(v):
		value = v
		_update_ui()
@export var background_color: Color = Color(0,0,0, 0.3):
	set(v):
		background_color = v
		_update_ui()
@export var bar_color: Color = Color(255, 255, 255, 0.3):
	set(v):
		bar_color = v
		_update_ui()
@export_file("*.jpg", "*.jpeg", "*.wav") var texture = ""
@export_file("*.gdshader") var shader = ""
@export_file("*.ttf", "*.otf") var font = ""
@export var font_color: Color = Color.WHITE
@export var font_size = 16.0

var background: TextureRect = null
var shader_material: ShaderMaterial = null
var blur: TextureRect = null
var center: CenterContainer = null
var vbox: VBoxContainer = null
var sb_bg: StyleBoxFlat = null
var sb_fill: StyleBoxFlat = null
var loading_bar: ProgressBar = null
var label_settings: LabelSettings = null
var label: Label = null
var debug_label_settings: LabelSettings = null
var debug_label: Label = null

func _ready() -> void:
	background = TextureRect.new()
	shader_material = ShaderMaterial.new()
	blur = TextureRect.new()
	center = CenterContainer.new()
	vbox = VBoxContainer.new()
	sb_bg = StyleBoxFlat.new()
	sb_fill = StyleBoxFlat.new()
	loading_bar = ProgressBar.new()
	label_settings = LabelSettings.new()
	label = Label.new()
	debug_label_settings = LabelSettings.new()
	debug_label = Label.new()
	
	self.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.texture = load(texture)
	shader_material.shader = load(shader)
	blur.texture = load(texture)
	blur.material = shader_material
	sb_bg.bg_color = background_color
	sb_bg.set_corner_radius_all(8)
	sb_fill.bg_color = bar_color
	sb_fill.set_corner_radius_all(8)
	loading_bar.min_value = 0.0
	loading_bar.max_value = 100.0
	loading_bar.custom_minimum_size.x = 400.0
	loading_bar.custom_minimum_size.y = 35.0
	loading_bar.value = value
	loading_bar.add_theme_stylebox_override("fill", sb_fill)
	loading_bar.show_percentage = false
	label_settings.font = load(font)
	label_settings.font_color = font_color
	label_settings.font_size = font_size
	label.label_settings = label_settings
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text = text
	debug_label_settings.font = load(font)
	debug_label_settings.font_color = font_color
	debug_label_settings.font_size = font_size - 2
	debug_label.label_settings = debug_label_settings
	debug_label.text = debug_text
	debug_label.custom_minimum_size.x = 250.0
	debug_label.custom_minimum_size.y = 25.0
	debug_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	debug_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	background.add_child(blur)
	center.add_child(vbox)
	loading_bar.add_child(label)
	vbox.add_child(loading_bar)
	vbox.add_child(debug_label)
	
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	blur.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	self.add_child(background)
	self.add_child(center)
	
	self.hide()

func _update_ui() -> void:
	if label:
		label.text = text
	if debug_label:
		debug_label.text = debug_text
	if loading_bar:
		loading_bar.value = value
