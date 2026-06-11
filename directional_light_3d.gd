extends DirectionalLight3D

@export var day_duration := 120.0
@export var sunrise_hour := 6.0
@export var sunset_hour := 20.0

var time := 8.0

var day_color := Color(1.0, 0.95, 0.8)
var sunset_color := Color(1.0, 0.5, 0.2)
var night_color := Color(0.1, 0.1, 0.3)

func _process(delta):
	time += (24.0 / day_duration) * delta
	if time >= 24.0:
		time = 0.0
	
	var sun_angle = (time / 24.0) * 360.0 + 90.0
	rotation_degrees.x = sun_angle
	
	if time < 5.8:
		light_color = night_color
		light_energy = lerp(light_energy, 0.05, delta * 2.0)
	elif time < 8.0:
		var progress = (time - 6.0) / 2.0
		light_color = sunset_color.lerp(day_color, progress)
		light_energy = lerp(light_energy, 1.5, delta * 0.5)
	elif time < 18.0:
		light_color = light_color.lerp(day_color, delta * 2.0)
		light_energy = lerp(light_energy, 1.5, delta * 2.0)
	elif time < 20.0:
		var progress = (time - 18.0) / 2.0
		light_color = day_color.lerp(sunset_color, progress)
		light_energy = lerp(light_energy, 0.8, delta * 0.5)
	else:
		light_color = light_color.lerp(night_color, delta * 0.5)
		light_energy = lerp(light_energy, 0.05, delta * 0.5)
	
	_update_enviroment()

func _update_enviroment():
	var env = get_viewport().get_camera_3d().get_environment() if get_viewport().get_camera_3d() else null
	if env == null:
		return
		
	if time < 6.0 or time > 20.0:
		env.ambient_light_energy = lerp(env.ambient_light_energy, 0.02, 0.05)
		env.ambient_light_color = Color(0.05, 0.05, 0.15)
	elif time < 8.0 or time > 18.0:
		env.ambient_light_energy = lerp(env.ambient_light_energy, 0.3, 0.05)
		env.ambient_light_color = Color(0.5, 0.3, 0.2)
	else:
		env.ambient_light_energy = lerp(env.ambient_light_energy, 1.0, 0.05)
		env.ambient_light_color = Color(1.0, 1.0, 1.0)
