extends RigidBody3D

# hinge join to the body, ragdoll
@onready var HEAD_COLL: CollisionShape3D = $CollisionShape3D

var LAUNCH_FACTOR = 530
var captured_by: Player = null
var picked_up = false
var last_captured_by: String = ''

func _ready():
	pass

@rpc("any_peer", "call_local")
func get_hooked():
	$DestroyTimer.start()
	$HookMax.start()
	freeze_near()

	if captured_by == null:
		$DestroyTimer.start()
		var playerId = multiplayer.get_remote_sender_id()
		for player in get_tree().get_nodes_in_group("Players"):
			if player.id == playerId:
				last_captured_by = get_team(player.id)
				captured_by = player
	else:
		$DestroyTimer.start()
		var playerId = multiplayer.get_remote_sender_id()
		for player in get_tree().get_nodes_in_group("Players"):
			if player.id == playerId:
				last_captured_by = get_team(player.id)
				captured_by = player
				picked_up = false

@rpc('any_peer', 'call_local', 'reliable')
func reserve(action):
	$HookMax.stop()
	# Note: can be id or null
	$DestroyTimer.start()
	# only allow an update if currently null.
	var playerId = multiplayer.get_remote_sender_id()
	# print(playerId, 'reservering', picked_up)
	if action == false and captured_by != null and playerId == captured_by.id and picked_up == true:
		picked_up = false
		captured_by = null
		return

	if playerId != null:
		if captured_by == null and picked_up == false:
			picked_up = true
			# HEAD_COLL.disabled = true
			for player in get_tree().get_nodes_in_group("Players"):
				if player.id == playerId:
					captured_by = player
					last_captured_by = get_team(player.id)
		elif playerId == captured_by.id and picked_up == true:
			picked_up = false
			captured_by = null
			# HEAD_COLL.disabled = false

@rpc("any_peer", 'call_local', 'reliable')
func launch():
	if captured_by != null:
		$DestroyTimer.start()
		apply_force(global_position.direction_to(captured_by.LOOKPOINT.global_position) * LAUNCH_FACTOR * Vector3(0.9, 2.2,1))
		picked_up = false
		captured_by = null
		HEAD_COLL.disabled = false
	else:
		$HookMax.start()

# NOTE: Weaponscast is a picker upper and it operates on LAYER 8.
func _physics_process(_delta):
	if picked_up == true and captured_by != null:
		_update_picked_object()
		return
	if captured_by != null and global_position.distance_to(captured_by.PICK_MARKER.global_transform.origin) > 1.2 and picked_up == false:
		var _direction = global_position.direction_to(captured_by.global_position).normalized()
		# NOTE: Removed distance factor because it was unreliable... could re-introduce.
		var _distance_factor = global_position.distance_to(captured_by.global_position)
		#if distance_factor < 6: 
		var cap = captured_by.PICK_MARKER.global_transform.origin
		var new_pick = Vector3(cap.x, cap.y + 0.3, cap.z)
		set_linear_velocity((new_pick - global_position) * 1.8)
		#else: 	
		#	apply_force(direction * 20)
	else:
		captured_by = null
		picked_up = false
	
func _update_picked_object():
	var a = global_transform.origin # here,
	var b = captured_by.PICK_MARKER.global_transform.origin # there
	set_linear_velocity((b - a) * 10)

func freeze_near():
	$DestroyTimer.start()
	freeze = true
	await get_tree().create_timer(0.1).timeout
	freeze = false


func destroy():
	if multiplayer.is_server():
		queue_free()

func Hit_Successful(_Source, _Damage, _Rotation, Position):
	var new_vec = global_transform.origin.direction_to(Position)
	apply_force(-Vector3(new_vec.x, new_vec.y - 2, new_vec.z) * 130)

# TODO: apply force
@rpc('any_peer', 'call_local')
func Hit_Melee(_Source, _Damage, _Direction, Position):
	var new_vec = global_transform.origin.direction_to(Position)
	apply_force(-Vector3(new_vec.x, new_vec.y - 1.7, new_vec.z) * 680)

func get_team(id):
	var _team = ''
	for p in get_tree().get_nodes_in_group('Players'):
		if p.id == id:
			_team = p.TEAM 
		
	return _team

func _on_hook_max_timeout():
	captured_by = null
	picked_up = false


func _on_destroy_timer_timeout():
	if multiplayer.is_server():
		queue_free()

