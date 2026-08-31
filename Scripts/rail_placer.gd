@tool
extends Node3D

@export var rail_scene: PackedScene
@export var segment_length := 2.0
@export var place_rails := false : set = _place_rails


func _place_rails(value: bool):
	if not value:
		return
	
	if not rail_scene:
		place_rails = false
		return
	
	for child in get_children():
		child.free()
	
	var tracks := []
	
	for node in get_parent().get_children():
		if node is Path3D:
			tracks.append(node)
	
	var total_rails := 0
	
	for path in tracks:
		
		if not path.curve:
			continue
		
		var curve_length = path.curve.get_baked_length()
		
		if curve_length <= 0.0:
			continue
		
		var segment_count := int(ceil(curve_length / segment_length))
		
		# --------------------------------------------------------
		# ALLE SCHIENEN AUF DIESE TRACK
		# --------------------------------------------------------
		for i in segment_count:
			
			var offset := i * segment_length
			offset = min(offset, curve_length)
			
			var baked_transform = path.curve.sample_baked_with_rotation(
				offset,
				true
			)
			
			var instance := rail_scene.instantiate()
			
			instance.name = path.name + "_Rail_" + str(i)
			
			add_child(instance)
			
			instance.owner = get_tree().edited_scene_root
			
			instance.global_transform = (
				path.global_transform * baked_transform
			)
			
			total_rails += 1
	
	print(
		"Finished! ",
		tracks.size(),
		" Tracks | ",
		total_rails,
		" Rails placed"
	)
	
	place_rails = false
