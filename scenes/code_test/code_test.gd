extends Node2D

@export var lift_coefficient : Curve
@export var resist_coefficient : Curve

@onready var line = $Line2D
@onready var line_2 = $Line2D2
@onready var line_3 = $Line2D3
@onready var line_4 = $Line2D4

var propeller_attack_angle = PI / 8
var vertical_velocity = Vector3(0.0, 0.0, 0.0)
var move_speed = 0.0
var propeller_square = 1.0
var lift_force = 0.0
var resist_force = 0.0
var mouse_pos = Vector2(0.0, 0.0)

func _ready():
	line_3.rotation = propeller_attack_angle

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	mouse_pos = get_global_mouse_position()
	mouse_pos /= 10
	vertical_velocity = Vector3(0.0, mouse_pos.y, 0.0)
	move_speed = mouse_pos.x
	line.points[1].x = move_speed
	line.points[1].y = vertical_velocity.y
	line_2.points[1].x = resist_force
	line_2.points[1].y = lift_force
	testing_function()

func testing_function():
	var current_attack_angle = propeller_attack_angle
	var parent = get_parent()
	var parent_velocity = Vector3(0.0, 0.0, 0.0)
	var propeller_normal = Vector3(0.0, 0.0, 1.0)
	propeller_normal = propeller_normal.rotated(Vector3(1.0, 0.0, 0.0), -propeller_attack_angle)
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
	
	var mov_speed2 = vertical_velocity.length()
	var move_speed_pow2 = mov_speed2 * mov_speed2
	var air_dencity = GlobalVariables.air_density
	var Y_force = lift_coef * air_dencity * move_speed_pow2 * 0.5 * propeller_square
	var X_force = resist_coef * air_dencity * move_speed_pow2 * 0.5 * propeller_square
	#X_force = 100
	#Y_force = 0
	line_4.points[1].x = -X_force
	line_4.points[1].y = Y_force
	var to_rotate = Vector2(-X_force, Y_force)
	to_rotate = to_rotate.rotated(-current_attack_angle)
	to_rotate = to_rotate.rotated(propeller_attack_angle)
	print(current_attack_angle)
	lift_force = to_rotate.y
	resist_force = to_rotate.x
