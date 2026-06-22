extends Node3D

# Defining connections
# Format: { "Track_A": ["Track_B", "Track_C"] }
# Means: train comes from Track_A, possible to go to Track_B or Track_C

@export var connections : Dictionary = {}
@export var trigger_distance := 5.0

var network : Node = null
var switch_states : Dictionary = {}

func _ready():
	add_to_group("rail_switch")
	await get_tree().process_frame
	network = get_tree().get_first_node_in_group("rail_network")
	if network:
		network.register_junctions(self)
	
	for from_track in connections.keys():
		switch_states[from_track] = 0
	
func get_next_track(from_track: String) -> String:
	if not connections.has(from_track):
		return ""
	var options = connections[from_track]
	if options.is_empty():
		return ""
	var index = switch_states.get(from_track, 0)
	return options[index]
	
func switch_left(from_track: String):
	if not connections.has(from_track):
		return
	var options = connections[from_track]
	var current = switch_states.get(from_track, 0)
	switch_states[from_track] = max(current - 1, 0)
	print("Railway_Switch left: ", connections[from_track][switch_states[from_track]])
	
func switch_right(from_track: String):
	if not connections.has(from_track):
		return
	var options = connections[from_track]
	var current = switch_states.get(from_track, 0)
	switch_states[from_track] = min(current + 1, options.size() - 1)
	print("Railway_Switch right: ", connections[from_track][switch_states[from_track]])
	
func is_near(progress: float, path_name: String) -> bool:
	if not connections.has(path_name):
		return false
	return abs(global_position.distance_to(
		network.get_track(path_name).curve.sample_baked(progress) + network.get_track(path_name).global_position)) < trigger_distance
