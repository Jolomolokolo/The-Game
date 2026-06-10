# IDEAS 1 (BARE MINIMUM): Screen/Health, Hupe, Sounds für Blinker, Hupe, etc
# IDEAS 2: Bremse auf Spacebar oder so, abfallende Spiegel oder andere Teile, funktionierende Spiegel
# IDEAS 3: Scheibenwische, haha, ausgestatteter Innenraum oder so ?!, automatisches Licht aktivierer, je nach Tageszeit

# Less particel and particles while still moving

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

# Lights
@onready var headlights = [$"SpotLight-left", $"SpotLight-right"]
@onready var blinker_left = [$"blinker-left-front", $"blinker-left-back"]
@onready var blinker_right = [$"bliner-right-front", $"bliner-right-back"]
@onready var blinker_warn = [$"blinker-left-front", $"bliner-right-front", $"blinker-left-back", $"bliner-right-back"]
@onready var brake_lights = [$"brakelight-left", $"brakelight-right"]

var headlights_on := false
var blinker_timer := 0.0
var blinker_state := false
var active_blinkers : Array = []

@export var max_car_health := 100.0
@export var damage_threshold := 3.0
@export var damage_multiplier := 5.0

var car_health = max_car_health
var last_velocity := Vector3.ZERO

@onready var smoke_particles = $SmokeParticles

func _ready():
	add_to_group("car")
	car_camera_first_view.current = false
	reverse_viewport_container.visible = false
	for lights in headlights:
		lights.visible = headlights_on
	for light in blinker_warn:
		light.visible = blinker_state
	for light in brake_lights:
		light.visible = false
	
func _physics_process(delta):
	if not player_inside:
		return
	
	if just_entered:
		just_entered = false
		return
	
	var velocity_diff = (linear_velocity - last_velocity).length()
	if velocity_diff > damage_threshold:
		var damage = (velocity_diff - damage_threshold) * damage_multiplier
		taken_car_damage(damage)
	last_velocity = linear_velocity
	
	if Input.is_action_just_pressed("headlights"):
		headlights_on = not headlights_on
		for light in headlights:
			light.visible = headlights_on
		
	if Input.is_action_just_pressed("blinker_left"):
		if active_blinkers == blinker_left:
			active_blinkers = []
		else:
			active_blinkers = blinker_left
			_reset_blinkers()
			
	if Input.is_action_just_pressed("blinker_right"):
		if active_blinkers == blinker_right:
			active_blinkers = []
		else:
			active_blinkers = blinker_right
			_reset_blinkers()
		
	if Input.is_action_just_pressed("blinker_warn"):
		if active_blinkers == blinker_warn:
			active_blinkers = []
			_reset_blinkers()
		else:
			active_blinkers = blinker_warn
			_reset_blinkers()
	
	if active_blinkers.size() > 0:
		blinker_timer += delta
		if blinker_timer >= 0.5:
			blinker_timer = 0.0
			blinker_state = not blinker_state
			for light in active_blinkers:
				light.visible = blinker_state
	
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
		for light in brake_lights:
			light.light_energy = 0.3
	elif back > 0:
		engine_force = 0.0
		brake = max_brake_force * back
		for light in brake_lights:
			light.light_energy = lerp(0.5, 3.0, back)
	elif forward > 0:
		engine_force = max_engine_force * forward
		brake = 0.0
		for light in brake_lights:
			light.light_energy = 0.3
	else:
		engine_force = 0.0
		brake = 10.0
		for light in brake_lights:
			light.light_energy = 0.3
	
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
	for light in brake_lights:
		light.visible = true
		light.light_energy = 0.3
	
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
	for light in brake_lights:
		light.visible = false

func _on_enter_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_ref = body
		body.nearby_car = self
	
func _on_enter_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("player") and not player_inside:
		player_ref = null
		body.nearby_car = null
	
func _reset_blinkers():
	blinker_timer = 0.0
	blinker_state = false
	for light in blinker_left + blinker_right + blinker_warn:
		light.visible = false
		
func taken_car_damage(amount: float):
	car_health -= amount
	car_health = max(car_health, 0.0)
	update_damage_visuals()
	if car_health <= 0.0:
		car_destroyed()
	
func car_destroyed():
	print("Car broken!")
	engine_force = 0.0
	brake = max_brake_force
	if player_inside:
		exit_car()
	
func update_damage_visuals():
	var health_percent = car_health / max_car_health
	
	if health_percent < 0.7:
		smoke_particles.emitting = true
		smoke_particles.amount = int(lerp(10.0, 100.0, 1.0 - health_percent))
	else:
		smoke_particles.emitting = false
