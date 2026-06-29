extends Node3D

signal direction_changed(new_direction: String)

@export var track_incoming : NodePath
@export var track_main : NodePath
@export var track_branch : NodePath

var current_direction := "main"

var _track_in : Path3D
var _track_main : Path3D
var _track_branch : Path3D

func _ready() -> void:
	_track_in = get_node(track_incoming)#
	_track_main = get_node(track_main)
	_track_branch = get_node(track_branch)
	
func switch_left(_from_track: String):
	set_direction("branch")
	
func switch_right(_from_track: String):
	set_direction("main")
	
func set_direction(dir: String):
	if current_direction == dir:
		return
	current_direction = dir
	emit_signal("direction_changed", dir)
	print("Switch: %s -> %s" % [name, dir.to_upper()])
	
func get_next_track_for(incoming: Path3D) -> Path3D:
	if incoming == _track_in:
		return _track_main if current_direction == "main" else _track_branch
	if incoming == _track_main or incoming == _track_branch:
		return _track_in
	return null
	
func _on_switch_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("train"):
		body.notify_junction_exit(self)
	
func _on_switch_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("train"):
		body.notify_junction_exit(self)
