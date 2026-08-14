@tool
extends EditorPlugin

func _enter_tree():
	# Kita daftarkan HumPla sebagai Custom Node
	# Argumen: (Nama Node, Base Node, Script-nya, File Icon)
	add_custom_type(
		"HumPlaEngine", 
		"CharacterBody2D",
		preload("HumPla.gd"),
		preload("icon.png")
	)

func _exit_tree():
	# Bersihkan saat plugin di-disable
	remove_custom_type("HumPlaEngine")
	remove_custom_type("HumPla")
