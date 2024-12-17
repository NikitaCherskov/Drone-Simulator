extends Node3D

@export var is_fixed = true

@onready var arm : SpringArm3D = $SpringArm3D

var SENS = 0.01

var real_rotation : Vector3 = Vector3(0.0, 0.0, 0.0)

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !is_fixed:
		arm.global_rotation = real_rotation

func _input(event):
	if event is InputEventMouseMotion:
		var relative = event.relative
		var rot = Vector3(relative.y, relative.x, 0.0)
		real_rotation = real_rotation + rot * SENS
