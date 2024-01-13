extends RigidBody3D

# hinge join to the body, ragdoll
@onready var HEAD_COLL: CollisionShape3D = $CollisionShape3D

var LAUNCH_FACTOR = 420
var captured_by: Player = null
var picked_up = false

func _ready():
	print('head ready')

@rpc("any_peer", "call_local")
func get_hooked():
	$DestroyTimer.start()
	if captured_by == null:
		$DestroyTimer.start()
		var playerId = multiplayer.get_remote_sender_id()
		for player in get_tree().get_nodes_in_group("Players"):
			if player.id == playerId:
				captured_by = player

@rpc('any_peer', 'call_local')
func reserve():
	# Note: can be id or null
	$DestroyTimer.start()
	# only allow an update if currently null.
	var playerId = multiplayer.get_remote_sender_id()
	print(playerId, 'reservering', picked_up)
	if playerId != null:
		if captured_by == null and picked_up == false:
			picked_up = true
			HEAD_COLL.disabled = true
			for player in get_tree().get_nodes_in_group("Players"):
				if player.id == playerId:
					captured_by = player
		elif playerId == captured_by.id and picked_up == true:
			picked_up = false
			captured_by = null
			HEAD_COLL.disabled = false

@rpc("any_peer", 'call_local')
func launch():
	$DestroyTimer.start()
	apply_force(global_position.direction_to(captured_by.LOOKPOINT.global_position) * LAUNCH_FACTOR * Vector3(0.9, 2.2,1))
	picked_up = false
	captured_by = null
	HEAD_COLL.disabled = false
	
	
func _physics_process(delta):
	if picked_up == true and captured_by != null:
		_update_picked_object()
		return
	if captured_by != null and global_position.distance_to(captured_by.global_position) > 1.5:
		var direction = global_position.direction_to(captured_by.global_position).normalized()
		# NOTE: Removed distance factor because it was unreliable... could re-introduce.
		# var distance_factor = global_position.distance_to(captured_by.global_position)
		apply_force(direction * 20)
	elif captured_by != null:
		# reset
		freeze_near()
		captured_by = null
	
func _update_picked_object():
	var a = global_transform.origin # here,
	var b = captured_by.PICK_MARKER.global_transform.origin # there
	set_linear_velocity((b - a) * 10)

func freeze_near():
	$DestroyTimer.start()
	freeze = true
	await get_tree().create_timer(0.1).timeout
	freeze = false

func _on_timer_timeout():
	if multiplayer.is_server():
		queue_free()

func destroy():
	if multiplayer.is_server():
		queue_free()

