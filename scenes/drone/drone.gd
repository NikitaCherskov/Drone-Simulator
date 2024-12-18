extends RigidBody3D

@export var engines : Array[DroneEngine]

const THROTTLE_POWER = 1.0
const PITCH_POWER = 0.05
const ROLL_POWER = 0.05
const YAW_POWER = 0.02

var target_powers = [0.0, 0.0, 0.0, 0.0]
var throttle : float = 0.0
var roll : float = 0.0
var pitch : float = 0.0
var yaw : float = 0.0

var roll_speed = 0.0
var pitch_speed = 0.0
var yaw_speed = 0.0

var mouse_pitch = 0.0
var mouse_roll = 0.0



func _process(delta):
	if Input.is_action_just_pressed("escape"):
		get_tree().quit()



func _physics_process(delta):
	axis_control()
	axis_speed_process()
	stabilize()
	axis_to_target_powers()
	target_to_engine_powers()



func target_to_engine_powers():
	var i : int = 0
	while i < engines.size():
		engines[i].set_throttle(target_powers[i])
		i += 1



func axis_to_target_powers():
	var tmp_throttle = throttle * THROTTLE_POWER
	var tmp_roll = roll * ROLL_POWER
	var tmp_pitch =  pitch * PITCH_POWER
	var tmp_yaw = yaw * YAW_POWER
	var negative_throttle = clampf(-tmp_throttle, 0.0, 1.0)
	var negative_roll = clampf(-tmp_roll, 0.0, 1.0)
	var negative_pitch = clampf(-tmp_pitch, 0.0, 1.0)
	var negative_yaw = clampf(-tmp_yaw, 0.0, 1.0)
	var abs_throttle = abs(tmp_throttle)
	var abs_roll = abs(tmp_roll)
	var abs_pitch = abs(tmp_pitch)
	var abs_yaw = abs(tmp_yaw)
	tmp_throttle = clampf(tmp_throttle, 0.0, 1.0)
	tmp_roll = clampf(tmp_roll, 0.0, 1.0)
	tmp_pitch = clampf(tmp_pitch, 0.0, 1.0)
	tmp_yaw = clampf(tmp_yaw, 0.0, 1.0)
	target_powers[0] = tmp_throttle + negative_roll + tmp_pitch + negative_yaw
	target_powers[1] = tmp_throttle + tmp_roll + tmp_pitch + tmp_yaw
	target_powers[2] = tmp_throttle + tmp_roll + negative_pitch + negative_yaw
	target_powers[3] = tmp_throttle + negative_roll + negative_pitch + tmp_yaw
	var max = 0.0
	for target_power in target_powers:
		if target_power > max:
			max = target_power
	if max > 0.0001:
		for i in range(0, target_powers.size()):
			target_powers[i] /= max
	var axis_sum = abs_throttle + abs_roll + abs_pitch + abs_yaw
	axis_sum = clampf(axis_sum, 0.0, 1.0)
	for i in range(0, target_powers.size()):
		target_powers[i] *= axis_sum
	mouse_pitch *= 0.7
	mouse_roll *= 0.7
	var v2 = linear_velocity.length() * linear_velocity.length()
	var force_amount = 0.5 * GlobalVariables.air_density * v2 * 0.02 * 0.38
	apply_central_force(-linear_velocity.normalized() * force_amount)



func axis_control():
	throttle = Input.get_axis("throttle_down", "throttle_up")
	roll = Input.get_axis("roll_left", "roll_right")
	pitch = Input.get_axis("pitch_down", "pitch_up")
	yaw = Input.get_axis("yaw_left", "yaw_right")
	roll = clamp(roll + mouse_roll, -1.0, 1.0)
	pitch = clamp(pitch + mouse_pitch, -1.0, 1.0)


func axis_speed_process():
	var rotate_vector = to_local(angular_velocity + position)
	roll_speed = rotate_vector.z
	pitch_speed = rotate_vector.x
	yaw_speed = rotate_vector.y


func stabilize():
	var roll_diff = roll + roll_speed * 0.1
	var pitch_diff = pitch - pitch_speed * 0.1
	var yaw_diff = yaw + yaw_speed * 0.1
	roll = mod_clamp(roll_diff, 2.0)
	pitch = mod_clamp(pitch_diff, 2.0)
	yaw = mod_clamp(yaw_diff, 4.0)
	throttle = (throttle + 1.0) / 2.0
	throttle = pow(throttle, 1.0 / 1.2)


func _input(event):
	if event is InputEventMouseMotion:
		mouse_pitch = -event.relative.y / 100.0
		mouse_roll = event.relative.x / 100.0


func mod_clamp(val : float, power : float):
	clamp(val, -1.0, 1.0)
	if val >= 0:
		return 1.0 - pow(abs(1.0 - val), power)
	else:
		return pow(abs(val + 1.0), power) - 1.0
