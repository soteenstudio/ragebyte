extends Node

static func randomize_appearance(base_path: String, sprite: NPCTyped):
	var files = HumPlaUtils._get_all_files_in_folder(base_path)
	var bodies: Array[String] = []
	var heads: Array[String] = []
	var legs: Array[String] = []
	
	for f in files:
		if f.ends_with(".png"):
			if f.begins_with("body"): bodies.append(f)
			elif f.begins_with("head"): heads.append(f)
			elif f.begins_with("legs"): legs.append(f)

	if bodies.size() > 0:
		var chosen_body = bodies.pick_random()
		sprite.sprite_body.texture = load(base_path + chosen_body)
		
		var body_number = chosen_body.replace("body", "").replace(".png", "")
		
		var hand_file = "hand" + body_number + ".png"
		
		if FileAccess.file_exists(base_path + hand_file):
			var hand_tex = load(base_path + hand_file)
			sprite.sprite_hand_near.texture = hand_tex
			sprite.sprite_hand_far.texture = hand_tex
		else:
			print("Warning: File " + hand_file + " gak ketemu!")

	if heads.size() > 0:
		var chosen_head = heads.pick_random()
		sprite.sprite_head.texture = load(base_path + chosen_head)
		
		var head_number = chosen_head.replace("head", "").replace(".png", "")
		
		var hair_file = "hair" + head_number + ".png"
		
		if FileAccess.file_exists(base_path + hair_file):
			var hair_tex = load(base_path + hair_file)
			sprite.sprite_hair.texture = hair_tex
		else:
			push_error("[Knifter] ", hair_file, " not found.")
		
	if legs.size() > 0:
		var leg_tex = load(base_path + legs.pick_random())
		sprite.sprite_leg_near.texture = leg_tex
		sprite.sprite_leg_far.texture = leg_tex
