# IDEAS: Kaput Scren/Healt, Spiegel abfallen oder einzelene Teile
# Drift - Bremese auf Spacebar, Blinker, Hupe, Licht, Scheibenwischer

extends VehicleBody3D

@export var max_engine_force := 1500.0
@export var max_brake_force := 80.0
@export var max_steering := 0.4
@export var reverse_force := 800.0
@export var enter_distance := 3.0

var player_inside := false
var player_ref : Node = null
var just_entered := false

@onready var car_camera_first_view = $"First-View"
@onready var car_camera_third_view = $"Third-View"
@onready var reverse_viewport_container = $SubViewportContainer
@onready var reverse_camera = $SubViewportContainer/SubViewport/Camera3D

func _ready():
	add_to_group("car")
	car_camera_first_view.current = false
	reverse_viewport_container.visible = false
	
func _physics_process(delta):
	if not player_inside:
		return
	
	if just_entered:
		just_entered = false
		return
	
	if Input.is_action_just_pressed("ui_interact"):
		exit_car()
		return
	
	if Input.is_action_just_pressed("camera_1"):
		car_camera_first_view.current = true
		car_camera_third_view.current = false
	if Input.is_action_just_pressed("camera_2"):
		car_camera_first_view.current = false
		car_camera_third_view.current = true
	
	var forward = Input.get_action_strength("ui_up")
	var back = Input.get_action_strength("ui_down")
	
	var speed = linear_velocity.dot(-global_transform.basis.z)
	if back > 0 and speed > 0.1: # Adden, das etwas überblende Zeit oder so
		reverse_viewport_container.visible = true
	else:
		reverse_viewport_container.visible = false
	
	if back > 0 and speed > -0.5:
		engine_force = -reverse_force * back
		brake = 0.0
	elif back > 0:
		engine_force = 0.0
		brake = max_brake_force * back
	elif forward > 0:
		engine_force = max_engine_force * forward
		brake = 0.0
	else:
		engine_force = 0.0
		brake = 10.0
		
	var steer_target = Input.get_axis("ui_right", "ui_left") * max_steering
	steering = lerp(steering, steer_target, delta * 8.0)
	
func enter_car(player):
	player_ref = player
	player_inside = true
	just_entered = true
	player_ref.hide()
	player_ref.set_physics_process(false)
	player_ref.set_collision_layer_value(1, false)
	player_ref.set_collision_mask_value(1, false)
	car_camera_first_view.current = true
	brake = 0.0
	
func exit_car():
	if player_ref == null:
		return
	player_inside = false
	car_camera_first_view.current = false
	engine_force = 0.0
	brake = max_brake_force
	steering = 0.0
	player_ref.global_position = global_position + global_transform.basis.x * 2.0
	player_ref.show()
	player_ref.set_physics_process(true)
	player_ref.notify_exit()
	var ref = player_ref
	player_ref = null
	await get_tree().create_timer(0.05).timeout
	if is_instance_valid(ref):
		ref.set_collision_layer_value(1, true)
		ref.set_collision_mask_value(1, true)

func _on_enter_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_ref = body
		body.nearby_car = self
	
func _on_enter_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("player") and not player_inside:
		player_ref = null
		body.nearby_car = null
