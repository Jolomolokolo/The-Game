# Player.gd
extends CharacterBody3D

@export var walk_speed := 5.0
@export var sprint_speed := 9.0
@export var jump_velocity := 5.5
@export var mouse_sensitivity := 0.2

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Camera
@onready var camera_pivot = $CameraPivot
@onready var camera_first_view = $"CameraPivot/First-View"
@onready var camera_third_view = $"CameraPivot/Third-View"

# Animation
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		
		# LEFT / RIGHT -> BODY rotate
		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))

		# UP / DOWN -> Only Camera
		camera_pivot.rotate_x(deg_to_rad(-event.relative.y * mouse_sensitivity))

		camera_pivot.rotation.x = clamp(
			camera_pivot.rotation.x,
			deg_to_rad(-80),
			deg_to_rad(80)
		)

	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):

	# Gravitation
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Jumping
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
		animation_player.play("jump")

	# Input
	var input_dir = Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
		"ui_down"
	)

	# Movement direction
	var direction = (
		transform.basis *
		Vector3(input_dir.x, 0, input_dir.y)
	).normalized()

	# Sprint
	var current_speed = walk_speed

	if Input.is_action_pressed("sprint"):
		current_speed = sprint_speed

	# Motion
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed

		if is_on_floor():
			if current_speed == sprint_speed:
				animation_player.play("sprint")
			else:
				animation_player.play("walk")
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

		if is_on_floor():
			animation_player.play("idle")
	
	move_and_slide()
