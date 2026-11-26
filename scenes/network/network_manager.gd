extends Node

signal player_joined(player_id: int, spawn_index: int)
signal player_data_received(player_id: int, data: Dictionary)

var peer: ENetMultiplayerPeer
var players_connected = {}
var local_player_id = 1
var is_server = false
var next_player_id = 2

const PORT = 8888
const SERVER_IP = "127.0.0.1"

func _ready():
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func start_server():
	print("[SERVER] Starte Server auf Port %d" % PORT)
	is_server = true
	peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT, 4)
	multiplayer.multiplayer_peer = peer

func connect_to_server():
	print("[CLIENT] Verbinde zu %s:%d" % [SERVER_IP, PORT])
	is_server = false
	peer = ENetMultiplayerPeer.new()
	peer.create_client(SERVER_IP, PORT)
	multiplayer.multiplayer_peer = peer

func _on_connected_to_server():
	print("[CLIENT] Mit Server verbunden!")
	request_spawn.rpc_id(1)

func _on_server_disconnected():
	print("[CLIENT] Server getrennt!")

func _on_peer_connected(id: int):
	print("[SERVER] Peer %d verbunden" % id)
	players_connected[id] = true
	
	var spawn_index = (id - 2) % 2
	player_joined.emit(id, spawn_index)
	notify_new_player.rpc_id(id, id, spawn_index)

func _on_peer_disconnected(id: int):
	print("[SERVER] Peer %d getrennt" % id)
	players_connected.erase(id)

@rpc("any_peer", "reliable")
func request_spawn():
	var caller_id = multiplayer.get_remote_sender_id()
	var spawn_index = (caller_id - 2) % 2
	print("[SERVER] Spawn-Request von %d, Index: %d" % [caller_id, spawn_index])
	notify_new_player.rpc_id(caller_id, caller_id, spawn_index)

@rpc("authority", "reliable")
func notify_new_player(player_id: int, spawn_index: int):
	player_joined.emit(player_id, spawn_index)

func send_player_data(player: Node3D):
	if not is_multiplayer_authority():
		return
	
	var data = {
		"position": player.global_position,
		"rotation": player.global_rotation,
		"velocity": player.velocity if player.has_meta("velocity") else Vector3.ZERO
	}
	
	broadcast_player_update.rpc(multiplayer.get_unique_id(), data)

@rpc("authority", "unreliable")
func broadcast_player_update(player_id: int, data: Dictionary):
	player_data_received.emit(player_id, data)
