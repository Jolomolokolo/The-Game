extends Node3D

# Defining connections
# Format: { "Track_A": ["Track_B", "Track_C"] }
# Means: train comes from Track_A, possible to go to Track_B or Track_C

@export var trigger_distance := 15.0
@export var switch_progress : float = 0.0

var network : Node = null
var switch_states : Dictionary = {}
var connections : Dictionary = {}

func _ready():
	add_to_group("rail_switch")
	await get_tree().process_frame
	network = get_tree().get_first_node_in_group("rail_network")
	if network:
		network.register_junctions(self)
	
	for from_track in connections.keys():
		switch_states[from_track] = 0
	
func setup(conn: Dictionary):
	connections = conn
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
	print("switch_left aufgerufen, from_track: ", from_track)
	print("connections hat from_track: ", connections.has(from_track))
	if not connections.has(from_track):
		return
	
	
	
	if not connections.has(from_track):
		return
	var _options = connections[from_track]
	var current = switch_states.get(from_track, 0)
	switch_states[from_track] = max(current - 1, 0)
	print("Railway_Switch left: ", connections[from_track][switch_states[from_track]])
	
func switch_right(from_track: String):
	print("switch_right aufgerufen, from_track: ", from_track)
	print("connections hat from_track: ", connections.has(from_track))
	if not connections.has(from_track):
		return
	
	
	
	if not connections.has(from_track):
		return
	var options = connections[from_track]
	var current = switch_states.get(from_track, 0)
	switch_states[from_track] = min(current + 1, options.size() - 1)
	print("Railway_Switch right: ", connections[from_track][switch_states[from_track]])
	
func is_near(progress: float, path_name: String) -> bool:
	if not connections.has(path_name):
		return false
	var track = network.get_track(path_name)
	if track == null:
		return false
	
	var track_length = track.curve.get_baked_length()
	var normalized_progress = fmod(progress, track_length)
	
	var track_pos = track.global_position + track.curve.sample_baked(normalized_progress)
	var dist = global_position.distance_to(track_pos)
	print("Distanz zur Weiche: ", dist)
	return dist < trigger_distance
