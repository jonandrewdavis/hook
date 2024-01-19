extends Node

# NOTE: IMPORTANT!!!
# Whenever you have an issue with network calls not passing in parameters, 
# CHECK that you are using .rpc()  to call it. Otherwise, it'll call locally
#  and that is the the source of 99% of bugs. AD, 6/12/2023

# e is event / emit, whatever. just short.
signal e

var is_headless_mode = false
var client_join_info = {}
var upnp_host_ip = ''

# NOTE: players[id] for access, where `id` is an int
# NOTE: Could name the store "state", but I think we'll keep this name for now, 
# even if a little redundant. 

# 		"id": multiplayer.get_unique_id(),
#		"nickname": nickname.text,
#		"color": color_button.color,


var store = {
	"players" : {},
	"red_score": 0,
	"blue_score": 0,
	"log": '',
	"log_count": 0,
}

func _ready():
	multiplayer.peer_connected.connect(func(_id): self.on_player_join.rpc(_id))

# Any player who joins should trigger a state change
@rpc("any_peer", "reliable")
func on_player_join(_id):
	set_state.rpc('client_join', client_join_info)

# Called from any client, or peer.
# TODO: Create an enum of "reducer" actions like "client_join" and "client_leave" 
# NOTE: Always do elif, or 2 conditions can fire...
@rpc("any_peer", "call_local", "reliable")
func set_state(key, value):
	if multiplayer.is_server():
		if store.log_count < 14:
			store.log_count += 1
		else:
			store.log_count = 0
			store.log = ""
		if key == 'client_join':
			store.players[value.id] = value
		elif key == 'client_leave':
			store.players.erase(value)
		elif key == 'blue_score':
			store.log += 'Blue just scored!' + '\n'
			store.blue_score += 1
		elif key == 'red_score':
			store.log += 'Red just scored!' + '\n'
			store.red_score += 1
		else:
			store[key] = value
		set_store.rpc(store)
		
@rpc("any_peer", "call_local", "reliable")
func set_player(id, key, _value):
	if id == 0:
		return
	if multiplayer.is_server():
		if store.players.has(id) == false:
			return
		if store.log_count < 11:
			store.log_count += 1
		else:
			store.log_count = 0
			store.log = ""
		if key == 'kills':
			store.log += str(store.players[id].nickname) + ' got a kill' + '\n'
			store.players[id][key] += 1
		elif key == 'deaths':
			store.log += str(store.players[id].nickname) + ' died a terrible death' + '\n'
			store.players[id][key] += 1
		else:
			store.players[id][key] = _value
		set_store.rpc(store)

# Only the server can propagate updates, as it always has the latest. 
@rpc("authority", "call_local", "reliable")
func set_store(_store):
	store = _store
	e.emit()
