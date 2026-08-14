@tool
extends EditorPlugin

var tab_button: Button

func _enter_tree():
	# Cek apakah kita lagi jalan di Android/iOS (Editor Mobile)
	# Kalau mau ngetes di PC dulu, hapus kondisional OS-nya
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		_setup_tab_button()

func _setup_tab_button():
	tab_button = Button.new()
	tab_button.text = "TAB"
	
	# Styling dasar biar enak dipencet di HP
	tab_button.custom_minimum_size = Vector2(80, 80)
	
	# Connect signal biar pas dipencet ngirim input Tab
	tab_button.gui_input.connect(_on_button_gui_input)
	
	# Menambahkan button ke area Left BL (Bottom Left) di Editor Godot
	add_control_to_container(CONTAINER_CANVAS_EDITOR_MENU, tab_button)
	# Atau pakai CONTAINER_SPATIAL_EDITOR_MENU buat 3D editor

func _on_button_gui_input(event):
	if event is InputEventScreenTouch and event.pressed:
		_simulate_tab_key(true)
	elif event is InputEventScreenTouch and !event.pressed:
		_simulate_tab_key(false)

func _simulate_tab_key(is_pressed: bool):
	var ev = InputEventKey.new()
	ev.pressed = is_pressed
	ev.keycode = KEY_TAB
	# Kirim event langsung ke engine
	Input.parse_input_event(ev)

func _exit_tree():
	if tab_button:
		remove_control_from_container(CONTAINER_CANVAS_EDITOR_MENU, tab_button)
		tab_button.queue_free()
