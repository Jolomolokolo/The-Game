extends Node3D

@export var wagon_spacing := 8.0
@export var wagon_index := 1

@onready var path_follow : PathFollow3D = get_parent()
@onready var train : Node = get_tree().get_first_node_in_group("train")
@onready var collision_body = $StaticBody3D

func _physics_process(_delta):
	if train == null:
		return
	
	collision_body.global_position = global_position
	collision_body.global_rotation = global_rotation
	
	var train_follow : PathFollow3D = train.get_parent()
	path_follow.progress = train_follow.progress - (wagon_spacing * wagon_index)
