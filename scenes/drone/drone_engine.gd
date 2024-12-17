extends Node3D
class_name DroneEngine

@onready var slow_propeller : MeshInstance3D = $SimpleDroneSimpleSlowPropeller
@onready var fast_propeller : MeshInstance3D = $SimpleDroneSimpleFastPropeller

@export var clockwise : bool = false
@export var power : float = 3
@export var torque_power : float = 2
@export var lift_coefficient : Curve
@export var resist_coefficient : Curve

const propeller_attack_angle = 0.26
const propeller_radius = 0.075
const propeller_half_radius = propeller_radius
const propeller_square = 0.0015
const propeller_mass = 0.02
const propeller_inertia_moment = propeller_mass * propeller_radius * propeller_radius
const engine_max_moment = 0.02
const max_slip = 0.05

var move_speed = 0.0
var lift_force = 0.0
var resist_force = 0.0
var angle_speed = 0.0
var torque_moment = 0.0
var magnetic_angle_speed = 0.0

var throttle : float = 0.0

func set_throttle(_throttle : float):
	throttle = clampf(_throttle, 0.0, 1.0)

func _physics_process(delta):
	var parent = get_parent()
	if parent is RigidBody3D:
		var force = to_global(Vector3(0.0, lift_force, 0.0)) - global_position
		var torque = to_global(Vector3(0.0, -resist_force, 0.0)) - global_position
		var force_pos = global_position - parent.global_position
		parent.apply_force(force, force_pos)
		if clockwise:
			parent.apply_torque(-torque)
		else:
			parent.apply_torque(torque)
	properller_process(delta)
	calculate_engine(delta)
	calculate_forces()
	calculate_move_speed()

func properller_process(delta):
	var rotate_axis = Vector3(0.0, 0.0, 0.0)
	if clockwise:
		rotate_axis = Vector3(0.0, 1.0, 0.0)
	else:
		rotate_axis = Vector3(0.0, -1.0, 0.0)
	slow_propeller.rotate(rotate_axis, angle_speed * delta)
	fast_propeller.rotate(rotate_axis, angle_speed * delta)
	fast_propeller.visible = angle_speed * delta > 6

func calculate_engine(delta):
	magnetic_angle_speed = angle_speed / (1.0 - max_slip)
	magnetic_angle_speed = clamp(magnetic_angle_speed, 10, 125663)
	var slip = (magnetic_angle_speed - angle_speed) / magnetic_angle_speed
	torque_moment = engine_max_moment * throttle
	#if abs(slip) > 0.0001:
	#	torque_moment = (2 * engine_max_moment) / (slip/max_slip + max_slip/slip)
	#	torque_moment *= throttle
	#else:
	#	torque_moment = 0.0

func calculate_forces():
	var current_attack_angle = propeller_attack_angle
	var parent = get_parent()
	var vertical_velocity = Vector3(0.0, 0.0, 0.0)
	var parent_velocity = Vector3(0.0, 0.0, 0.0)
	var propeller_normal = Vector3(0.0, 0.0, 1.0)
	propeller_normal = propeller_normal.rotated(Vector3(1.0, 0.0, 0.0), -propeller_attack_angle)
	if parent is RigidBody3D:
		parent_velocity = parent.linear_velocity
		#print(parent_velocity.length())
	vertical_velocity = to_local(parent_velocity + global_position)
	vertical_velocity = Vector3(0.0, vertical_velocity.y, 0.0)
	vertical_velocity += Vector3(0.0, 0.0, move_speed)
	var vertical_velocity2 = Vector2(vertical_velocity.z, vertical_velocity.y)
	var propeller_normal2 = Vector2(propeller_normal.z, propeller_normal.y)
	current_attack_angle = vertical_velocity2.angle_to(propeller_normal2)
	
	var curve_attack_angle = current_attack_angle / (2 * PI) + 0.5
	var lift_coef = 0.0
	var resist_coef = 0.0
	if lift_coefficient != null:
		lift_coef = lift_coefficient.sample_baked(curve_attack_angle)
	if resist_coefficient != null:
		resist_coef = resist_coefficient.sample_baked(curve_attack_angle)
	
	var move_speed2 = move_speed + vertical_velocity.length()
	var move_speed_pow2 = move_speed2 * move_speed2
	var air_dencity = GlobalVariables.air_density
	var Y_force = lift_coef * air_dencity * move_speed_pow2 * 0.5 * propeller_square
	var X_force = resist_coef * air_dencity * move_speed_pow2 * 0.5 * propeller_square
	Y_force *= 0.007
	X_force *= 0.007
	var to_rotate = Vector2(-X_force, Y_force)
	to_rotate = to_rotate.rotated(-current_attack_angle)
	to_rotate = to_rotate.rotated(propeller_attack_angle)
	lift_force = to_rotate.y
	resist_force = to_rotate.x
	#print(angle_speed / (PI*2))
	#print(current_attack_angle)

func calculate_move_speed():
	var torque_force = torque_moment / propeller_half_radius
	move_speed += (resist_force + torque_force) / propeller_mass
	angle_speed = move_speed / propeller_half_radius
