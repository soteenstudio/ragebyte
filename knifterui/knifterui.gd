@tool
extends EditorPlugin

var terminal_panel

func _enter_tree():
	terminal_panel = preload("ui/knifter.tscn").instantiate()
	
	# Daftarin dulu ke panel bawah
	add_control_to_bottom_panel(terminal_panel, "Knifter")
	
	# Paksa setting ulang SETELAH dia resmi jadi bagian dari Editor UI
	terminal_panel.call_deferred("set_anchors_and_offsets_preset", Control.PRESET_FULL_RECT)
	terminal_panel.call_deferred("set_h_size_flags", Control.SIZE_EXPAND_FILL)
	terminal_panel.call_deferred("set_v_size_flags", Control.SIZE_EXPAND_FILL)
	
	var editor_root = get_editor_interface().get_base_control()
	_find_and_change_version_label(editor_root)

func _exit_tree():
	if terminal_panel:
		remove_control_from_bottom_panel(terminal_panel)
		terminal_panel.queue_free()

func _find_and_change_version_label(node: Node):
	# Kita cari Label yang isinya mengandung string versi Godot
	if node is Label and node.text.contains("4.6.1"):
		node.text = "Ragebyte 1.0.0.proto.0" # Ganti sesukamu
		return
	
	for child in node.get_children():
		_find_and_change_version_label(child)
