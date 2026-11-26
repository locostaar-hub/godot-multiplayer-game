extends VehicleBody3D

@export var engine_power = 100.0
@export var steering_speed = 0.1
@export var max_steering = 0.5

var current_steering = 0.0
var brake_input = 0.0

func _ready():
	print("Auto erstellt")

func _process(delta):
	var input_steering = Input.get_axis("ui_left", "ui_right")
	current_steering = move_toward(current_steering, input_steering * max_steering, steering_speed)
	steering = current_steering
	
	var engine_input = Input.get_axis("ui_down", "ui_up")
	engine_force = engine_input * engine_power
	
	brake_input = 1.0 if Input.is_action_pressed("ui_down") else 0.0
	brake = brake_input
