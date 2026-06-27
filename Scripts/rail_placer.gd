@tool
extends Node3D

@export var path : Path3D
@export var rail_scene : PackedScene
@export var segment_length := 2.0
@export var track_id : String = "track_a"
@export var place_rails := false : set = _place_rails

func _place_rails(value: bool):
	if not value:
		return
	if not path or not rail_scene:
		place_rails = false
		return
	
	var curve_length = path.curve.get_baked_length()
	var segment_count = int(curve_length / segment_length)
	
	if segment_count > 500:
		place_rails = false
		return
	
	for child in get_children():
		if child.name.begins_with(track_id + "_"):
			child.queue_free()
	
	await get_tree().process_frame
		
	for i in segment_count:
		var offset = i * segment_length
		var transform = path.curve.sample_baked_with_rotation(offset, true)
		
		var instance = rail_scene.instantiate()
		instance.name = track_id + "_" + str(i)
		add_child(instance)
		instance.owner = get_tree().edited_scene_root
		instance.global_transform = path.global_transform * transform
	
	print("Finished! ", get_child_count(), " Rails placed")
	place_rails = false
