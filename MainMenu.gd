extends Control

const PORT = 8888
var upnp_on = false
var quick_quit_enabled = true

@onready var world_ref = get_node('/root/Main/World')
@onready var ip_ref = $Panel/MarginContainer/VBoxContainer/IP
@onready var nickname = $Panel/MarginContainer/VBoxContainer/Nickname
@onready var upnp_ref = $Panel/MarginContainer/VBoxContainer/UPNP
@onready var color_button = $Panel/MarginContainer/VBoxContainer/ColorPickerButton
@onready var error_ref = $Panel/MarginContainer/VBoxContainer/Error

func _ready():
	prepare_server_or_client()
	prepare_color_picker()
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_connected_fail)	

func _unhandled_input(_event):
	if (Input.is_action_just_pressed("esc") 
	and OS.is_debug_build() == true 
	and quick_quit_enabled == true):
		get_tree().quit()		

func prepare_server_or_client():
	var args = OS.get_cmdline_user_args()
	for arg in args:
		var key_value = arg.rsplit("=")
		match key_value[0]:
			"server":
				print('DEBUG: SERVER STARTING `-- server` found')
				Store.is_headless_mode = true
				await get_tree().create_timer(1).timeout
				_on_host_pressed()
	# If there are no CMD line args, we are a client.
	if args.size() == 0:
		# OPTIONAL: Create a text file with this name, it won't be added to git.
		# When you export, the server IP will be pre-filled for clients.  
		# Try not to expose this IP, as I think bad actors could take advantage of open ports
		ip_ref.text = read_secret_ip("res://DEDICATED_SERVER_SECRET.txt")

func _on_host_pressed():
	var peer = ENetMultiplayerPeer.new()	
	peer.create_server(PORT)
	multiplayer.allow_object_decoding  = true
	multiplayer.multiplayer_peer = peer
	if upnp_on == true:
		upnp_setup()
	start_game()

func _on_join_pressed():
	var ip = ip_ref.text
	var peer = ENetMultiplayerPeer.new()
	var peer_client_status = peer.create_client(ip, PORT)
	if peer_client_status == OK:
		multiplayer.allow_object_decoding  = true
		multiplayer.multiplayer_peer = peer
		start_game()
	else: 
		_on_connected_fail()

func _on_connected_fail():
	multiplayer.multiplayer_peer = null
	error_ref.show()
	show()

func start_game():
	# If we're a client, we just hide and send our join info.
	hide()
	Store.client_join_info = {
		"id": multiplayer.get_unique_id(),
		"nickname": nickname.text,
		"color": color_button.color,
	}
	
	if multiplayer.is_server():
		change_level.call_deferred(load("res://Levels/Lobby.tscn"))

func change_level(scene: PackedScene):
	for c in world_ref.get_children():
		world_ref.remove_child(c)
		c.queue_free()
	
	# Add the chosen level to the world
	world_ref.add_child(scene.instantiate())
	# Connect the scripts required to listen for player events.
	ready_server_world()

func _on_upnp_toggled(toggled_on):
	upnp_on = toggled_on

func upnp_setup():
	var upnp = UPNP.new()
	
	var discover_result = upnp.discover()
	assert(discover_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Discover Failed! Error %s" % discover_result)

	assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), \
		"UPNP Invalid Gateway!")

	var map_result = upnp.add_port_mapping(PORT)
	assert(map_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Port Mapping Failed! Error %s" % map_result)
	
	print("Success! Join Address: %s" % upnp.query_external_address())
	Store.upnp_host_ip = str(upnp.query_external_address())

func read_secret_ip(path):
	var file = FileAccess.open(path, FileAccess.READ)
	if file != null:
		var content = file.get_as_text()
		return content
	else:
		return ''

func ready_server_world():
	# Welcome players
	# Only the server listens for events of peers connecting or disconnecting:
	# NOTE: A player will update state on joining so that everyone has their new info!
	if multiplayer.is_server():
		multiplayer.peer_connected.connect(add_player_in_server)
		multiplayer.peer_disconnected.connect(delete_player_in_server)
		
		for id in multiplayer.get_peers():
			add_player_in_server(id)
		
		if Store.is_headless_mode == false:
			add_player_in_server(1)

func add_player_in_server(id: int):
	var character_scene = preload("res://Player/Player.tscn")
	var character =  character_scene.instantiate()
	character.name = str(id)
	world_ref.add_child(character, true)	

func delete_player_in_server(id: int):
	var string_id = str(id)
	if world_ref.get_node(string_id).is_in_group('players'):
		world_ref.get_node(string_id).queue_free()
		Store.set_state.rpc('client_leave', id)

func _exit_tree():
	if multiplayer.is_server():
		multiplayer.peer_connected.disconnect(add_player_in_server)
		multiplayer.peer_disconnected.disconnect(delete_player_in_server)

func prepare_color_picker():
	var props = ['presets_visible', 'sampler_visible', 'sliders_visible', 'color_modes_visible']
	var picker = color_button.get_picker()
	for p in props:
		picker[p] = false
