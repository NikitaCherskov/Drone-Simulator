extends Node3D

@export var is_fixed = true
@export var target_object : Node3D = null

@onready var arm : SpringArm3D = $SpringArm3D
@onready var cam : Camera3D = $SpringArm3D/Camera3D

var DRONE_SIZE = 0.2
var SAVE_RECT_COORD : bool = false
var SENS = 0.01

var real_rotation : Vector3 = Vector3(0.0, 0.0, 0.0)
var screenshot_num = 0



func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	load_screenshot_num()



func _process(delta):
	if !is_fixed:
		arm.global_rotation = real_rotation
	if Input.is_action_just_pressed("screenshot"):
		take_screenshot()



func _input(event):
	if event is InputEventMouseMotion:
		var relative = event.relative
		var rot = Vector3(relative.y, relative.x, 0.0)
		real_rotation = real_rotation + rot * SENS



func load_screenshot_num():
	var num_path = "C:/Users/User/Documents/yolo_dataset/num/"
	var num_inst_path = num_path + "num.txt"
	if FileAccess.file_exists(num_inst_path):
		var file = FileAccess.open(num_inst_path, FileAccess.READ)
		if file != null:
			var txt = file.get_as_text()
			screenshot_num = int(txt)
		else:
			print("file is null")



func get_drone_rect():
	var rect : Rect2
	var screen_rect_size = Vector2(0.0, 0.0)
	var screen_rect_position = Vector2(0.0, 0.0)
	if target_object != null:
		screen_rect_position = cam.unproject_position(target_object.global_position)
		var screen_size : Vector2 = DisplayServer.screen_get_size()
		var screen_ratio = screen_size.x / screen_size.y
		screen_rect_position /= Vector2(screen_size)
		var loc_pos = to_local(target_object.global_position)
		var loc_pos_len = loc_pos.length()
		var half_fov = deg_to_rad(cam.fov / 2.0)
		var scaler = abs(sin(half_fov) / cos(half_fov))
		var screen_rect_size_axis = DRONE_SIZE / (scaler * loc_pos_len)
		screen_rect_size = Vector2(screen_rect_size_axis / screen_ratio, screen_rect_size_axis)
	rect.position = screen_rect_position
	rect.size = screen_rect_size
	return rect



func take_screenshot():
	var img_path = "C:/Users/User/Documents/yolo_dataset/img/"
	var txt_path = "C:/Users/User/Documents/yolo_dataset/txt/"
	var num_path = "C:/Users/User/Documents/yolo_dataset/num/"
	
	var img_inst_path = img_path + str(screenshot_num) + ".jpg"
	var txt_inst_path = txt_path + str(screenshot_num) + ".txt"
	var num_inst_path = num_path + "num.txt"
	
	var image = get_viewport().get_texture().get_image()
	image.save_jpg(img_inst_path)
	
	var drone_rect = get_drone_rect()
	
	if SAVE_RECT_COORD == true:
		var txt_file = FileAccess.open(txt_inst_path, FileAccess.WRITE)
		if txt_file != null:
			var target_class_txt = "0 "
			var target_position_txt = str(drone_rect.position.x) + " " + str(drone_rect.position.y) + " "
			var target_size_txt = str(drone_rect.size.x) + " " + str(drone_rect.size.y)
			txt_file.store_string(target_class_txt + target_position_txt + target_size_txt)
		else:
			print("txt_file is null")
		txt_file = null
		screenshot_num += 1
	
	var num_file = FileAccess.open(num_inst_path, FileAccess.WRITE)
	if num_file != null:
		num_file.store_string(str(screenshot_num))
	else:
		print("num_file is null")



func set_target_object(_target_object : Node3D):
	target_object = _target_object
