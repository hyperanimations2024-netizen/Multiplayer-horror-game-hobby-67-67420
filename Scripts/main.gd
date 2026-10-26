extends Node3D

const PLAYER_CONTROLLER = preload("uid://ckyxsmhvx6d4p")
@export var NETWORK_PLAYER:PackedScene
@onready var host_button: Button = $CanvasLayer/VBoxContainer/Button
@onready var ui: CanvasLayer = $CanvasLayer

var players: Array[CharacterBody3D]

func _ready() -> void:
	Networking.host_created.connect(on_host_created)
	

func on_host_created() -> void:
	# Spawn the server player
	spawn_player(multiplayer.get_unique_id())
	multiplayer.peer_connected.connect(spawn_player)


# The server spawns the player that just connected
func spawn_player(peer_id: int) -> void:
	var new_player := PLAYER_CONTROLLER.instantiate() as CharacterBody3D
	new_player.name = str(peer_id)
	add_child(new_player)
	initialize_player(new_player)
	


func spawn_local_player(id:int):
	var player = NETWORK_PLAYER.instantiate()
	player.name = str(id)
	call_deferred("add_child",player)
	players.append(player)
	player.position = $Spawnpoint.position
	for other in players:
		player.add_collision_exception_with(other)
	

func initialize_player(player: CharacterBody3D) -> void:
	player.position = $Spawnpoint.position
	players.append(player)
	for other in players:
		player.add_collision_exception_with(other)

func _on_button_pressed() -> void:
	Networking.host_lobby()
	host_button.hide()

func _on_multiplayer_spawner_spawned(node: Node) -> void:
	if node is CharacterBody3D:
		initialize_player(node)
	

func _on_local_host_pressed() -> void:
	Networking.start_local_server()
	multiplayer.peer_connected.connect(spawn_local_player)
	spawn_local_player(multiplayer.get_unique_id())
	ui.hide()

func _on_local_join_pressed() -> void:
	Networking.start_local_client()
	ui.hide()
