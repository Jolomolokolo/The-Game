extends Node3D

var tracks : Dictionary = {}
var junctions : Array = []

func _ready():
	add_to_group("rail_network")
	await get_tree().process_frame
	_build_network()
	
func _build_network():
	for child in get_children():
		if child is Path3D:
			tracks[child.name] = child
	print("Tracks registered: ", tracks.keys())
	
func register_junctions(junction):
	junctions.append(junction)
	
func get_track(name: String) -> Path3D:
	return tracks.get(name, null)
