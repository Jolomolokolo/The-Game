@tool
extends Node3D

@export var path: Path3D
@export var rail_scene : PackedScene
@export var segment_length := 2.0
@export var place_rails := false : set = _place_rails

func _place_rails(value: bool):
	if not value or not path or not rail_scene:
		return
	
	for child in get_children():
		child.queue_free()
	
	var curve_length = path.curve.get_baked_length()
	
	var max_segments = 500
	var segment_count = int(curve_length / segment_length)
	
	if segment_count > max_segments:
		print("To many segments: ", segment_count)
		place_rails = false
		return
	
	for child in get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	for i in segment_count:
		var offset = i * segment_length
		var transform = path.curve.sample_baked_with_rotation(offset, true)
		
		var instance = rail_scene.instantiate()
		add_child(instance)
		instance.owner = get_tree().edited_scene_root
		instance.global_transform = path.global_transform * transform
	
	place_rails = false
	print("Rails placed: ", get_child_count())
