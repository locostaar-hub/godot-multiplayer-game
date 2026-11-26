extends CharacterBody3D

@export var speed = 5.0
@export var jump_force = 5.0
@export var sensitivity = 0.003
@export var gravity = -9.8

@onready var camera = $Camera3D
@onready var animation_player = $AnimationPlayer if has_node("AnimationPlayer") else null

var player_id: int = 0
var is_local: bool = false
var velocity = Vector3.ZERO
var mouse_captured = false
var rotation_x = 0.0

var target_position = Vector3.ZERO
var target_rotation = Quaternion.IDENTITY
var lerp_speed = 10.0

func _ready():
	print("Spieler %d erstellt (lokal: %s)" % [player_id, is_local])
	
	if is_local:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		camera.current = true
	else:
		camera.current = false
		for child in get_children():
			if child is Camera3D:
				child.queue_free()
	
	target_position = global_position
	target_rotation = global_rotation

func _input(event: InputEvent):
	if not is_local:
		return
	
	if event.is_action_pressed("ui_cancel"):
		mouse_captured = !mouse_captured
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if mouse_captured else Input.MOUSE_MODE_VISIBLE)
	
	if event is InputEventMouseMotion and mouse_captured:
		var mouse_delta = event.relative * sensitivity
		rotation_x -= mouse_delta.y
		rotation_x = clamp(rotation_x, -PI/2, PI/2)
		
		rotation.y -= mouse_delta.x
		camera.rotation.x = rotation_x

func _process(delta):
	if is_local:
		_handle_local_input()
		move_and_slide()
	else:
		global_position = global_position.lerp(target_position, lerp_speed * delta)
		global_rotation = global_rotation.slerp(target_rotation, lerp_speed * delta)

func _handle_local_input():
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var move_dir = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	velocity.x = move_dir.x * speed
	velocity.z = move_dir.z * speed
	
	velocity.y += gravity * get_physics_process_delta_time()
	
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_force

func update_remote_position(pos: Vector3):
	target_position = pos

func update_remote_rotation(rot: Vector3):
	target_rotation = Quaternion.from_euler(rot)
