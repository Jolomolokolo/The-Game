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
	
	if time >= sunrise_hour and time <= sunset_hour:
		var day_progress = (time - sunrise_hour) / (sunset_hour - sunrise_hour)
		if day_progress < 0.1 or day_progress > 0.9:
			light_color = sunset_color
			light_energy = lerp(0.0, 1.5, day_progress * 10.0) if day_progress < 0.1 else lerp(1.5, 0.0, (day_progress - 0.9) * 10.0)
		else:
			light_color = day_color
			light_energy = 1.5
	else:
		light_color = night_color
		light_energy = 0.1
	
	_update_enviroment()

func _update_enviroment():
	var env = get_viewport().get_camera_3d().get_environment() if get_viewport().get_camera_3d() else null
	if env == null:
		return
	
	if time >= sunrise_hour and time <= sunset_hour:
		env.ambient_light_energy = lerp(0.1, 1.0, (time - sunrise_hour) / (sunset_hour / sunrise_hour))
	else:
		env.ambient_light_energy = 0.1
