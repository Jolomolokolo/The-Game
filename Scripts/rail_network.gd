extends Node3D

var _switches : Array[Node] = []
var _depots : Array[Node] = []

func _ready():
	for child in get_children():
		if child.has_method("get_next_track_for"):
			_switches.append(child)
	print("RailNetwork: %d Switches registered" % _switches.size())
	
func get_next_track(current: Path3D, direction: int) -> Path3D:
	if current == null:
		return null
	for sw in _switches:
		var result = sw.get_next_track_for(current, direction)
		if result != null:
			return result
	return null
	
func get_next_switch_for(current_track: Path3D) -> Node:
	if current_track == null:
		return null
	for sw in _switches:
		if sw.get_from_track_name() == current_track.name:
			return sw
	return null
	
func get_switches() -> Array:
	return _switches
	
func register_depot(depot: Node) -> void:
	_depots.append(depot)
	print("RailNetwork: Depit registered: %s" %depot.depot_name)
	
func get_depots() -> Array:
	return _depots
	
func get_depot_by_id(id: String) -> Node:
	for d in _depots:
		if d.depot_id == id:
			return d
	return null
	
func get_train_depot(train: Node) -> Node:
	for d in _depots:
		if d.trains_inside.has(train):
			return d
	return null
