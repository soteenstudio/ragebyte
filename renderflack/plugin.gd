@tool
extends EditorPlugin

func _enter_tree():
	add_autoload_singleton("RenderFlack", "RenderFlack.gd")
	# Kita daftarkan HumPla sebagai Custom Node
	# Argumen: (Nama Node, Base Node, Script-nya, File Icon)
	add_custom_type(
		"FlackLoadingScreen",
		"Control",
		preload("FlackLoadingScreen.gd"),
		preload("icon.png")
	)
	
	add_custom_type(
		"VisualSun",
		"Node2D",
		preload("visual_sun.gd"),
		preload("icon.png")
	)
	
	add_custom_type(
		"VisualShadow",
		"ColorRect",
		preload("visual_shadow.gd"),
		preload("icon.png")
	)

func _exit_tree():
	# Bersihkan saat plugin di-disable
	remove_custom_type("FlackMap")
