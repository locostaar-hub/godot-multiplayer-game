extends Node3D

@onready var network_manager = $NetworkManager
@onready var spawn_points = [$SpawnPoint1, $SpawnPoint2]

var player_scene = preload("res://scenes/player/player.tscn")
var car_scene = preload("res://scenes/car/car.tscn")

var players = {}
var local_player = null

func _ready():
	print("=== Spiel gestartet ===")
	
	network_manager.connect("player_joined", Callable(self, "_on_player_joined"))
	network_manager.connect("player_data_received", Callable(self, "_on_player_data"))
	
	var spawn_pos = spawn_points[0].global_position
	local_player = player_scene.instantiate()
	local_player.player_id = 1
	local_player.is_local = true
	add_child(local_player)
	local_player.global_position = spawn_pos
	players[1] = local_player
	
	var car = car_scene.instantiate()
	add_child(car)
	car.global_position = spawn_pos + Vector3(10, 0, 0)
	
	network_manager.start_server()

func _on_player_joined(player_id: int, spawn_index: int):
	print("Spieler %d beigetreten" % player_id)
	
	var spawn_pos = spawn_points[spawn_index].global_position
	var remote_player = player_scene.instantiate()
	remote_player.player_id = player_id
	remote_player.is_local = false
	add_child(remote_player)
	remote_player.global_position = spawn_pos
	players[player_id] = remote_player

func _on_player_data(player_id: int, data: Dictionary):
	if player_id in players:
		var player = players[player_id]
		player.update_remote_position(data.get("position", player.global_position))
		player.update_remote_rotation(data.get("rotation", player.global_rotation))

func _process(_delta):
	if local_player:
		network_manager.send_player_data(local_player)
