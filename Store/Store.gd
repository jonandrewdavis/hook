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
var store = {
	"players" : {},
	"score": 0
}

func _ready():
	multiplayer.peer_connected.connect(func(_id): self.on_player_join.rpc(_id))

# Any player who joins should trigger a state change
@rpc("any_peer", "reliable")
func on_player_join(_id):
	set_state.rpc('client_join', client_join_info)

# Called from any client, or peer.
# TODO: Create an enum of "reducer" actions like "client_join" and "client_leave" 
@rpc("any_peer", "call_local", "reliable")
func set_state(key, value):
	if multiplayer.is_server():
		if key == 'client_join':
			store.players[value.id] = value
		if key == 'client_leave':
			store.players.erase(value)
		else:
			store[key] = value
		set_store.rpc(store)

# Only the server can propagate updates, as it always has the latest. 
@rpc("authority", "call_local", "reliable")
func set_store(_store):
	store = _store
	e.emit()
