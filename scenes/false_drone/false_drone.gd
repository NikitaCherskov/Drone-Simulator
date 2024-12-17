extends Node3D
var velocity = Vector3(0.0, 0.0, 0.0)
var SPEED = 40.0

func _process(delta):
	velocity.z = rotation.x
	velocity.x = rotation.z
	var rot = Vector3(0.0, 1.0, 0.0)
	velocity = velocity.rotated(rot, rotation.y)
	position += velocity * delta * SPEED
	pass
