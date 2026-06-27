extends Node3D

# Defining connections
# Format: { "Track_A": ["Track_B", "Track_C"] }
# Means: train comes from Track_A, possible to go to Track_B or Track_C

var connections : Dictionary = {}
var switch_states : Dictionary = {}
var train_inside := false
var switch_cooldown := false

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
	if not connections.has(from_track):
		return
	var current = switch_states.get(from_track, 0)
	switch_states[from_track] = max(current - 1, 0)
	print("Switch left: ", connections[from_track][switch_states[from_track]])
	
func switch_right(from_track: String):
	if not connections.has(from_track):
		return
	var options = connections[from_track]
	var current = switch_states.get(from_track, 0)
	switch_states[from_track] = min(current + 1, options.size() - 1)
	print("Switch right: ", connections[from_track][switch_states[from_track]])
	
func _on_body_entered(body: Node3D):
	if body.is_in_group("train_collision") and not switch_cooldown:
		train_inside = true
		var train = get_tree().get_first_node_in_group("train")
		if train:
			train.current_junction = self
			var next = get_next_track(train.current_track_name)
			if next != "":
				switch_cooldown = true
				train._switch_to_track(next)
				await get_tree().create_timer(1.0).timeout
				switch_cooldown = false
	
func _on_body_exited(body: Node3D):
	if body.is_in_group("train_collision"):
		train_inside = false
		var train = get_tree().get_first_node_in_group("train")
		if train:
			train.current_junction = null
	
