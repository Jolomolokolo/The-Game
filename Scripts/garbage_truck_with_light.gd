extends Node3D

@export var rotation_speed := 6.0
@export var arm_move_duration := 1.0
@export var arm_wait_time := 10.0

@onready var warn_light = $WarnLight
@onready var garbage_arm = $arm

#func _ready():
	#_arm_cycle()
	
func _process(delta: float):
	warn_light.rotate_y(rotation_speed * delta)
	
func _arm_cycle():
	while true:
		await _rotate_arm_to(-80.0)
		await get_tree().create_timer(arm_wait_time).timeout
		await _rotate_arm_to(0.0)
		await get_tree().create_timer(arm_wait_time).timeout
	
func _rotate_arm_to(target_degrees: float) -> void:
	var tween = create_tween()
	tween.tween_property(garbage_arm, "rotation:x", deg_to_rad(target_degrees), arm_move_duration)
	await tween.finished
