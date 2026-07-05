extends Node3D

var _switches : Array[Node] = []

func _ready():
	for child in get_children():
		if child.has_method("get_next_track_for"):
			_switches.append(child)
	print("RailNetwork: %d Switches registered" % _switches.size())
	
func get_next_track(current: Path3D, direction: int) -> Path3D:
	for sw in _switches:
		var result = sw.get_next_track_for(current, direction)
		if result != null:
			return result
	return null
	
func get_next_switch_for(current_track: Path3D) -> Node:
	for sw in _switches:
		if sw.get_from_track() == current_track:
			return sw
	return null
	
func get_switches() -> Array:
	return _switches
