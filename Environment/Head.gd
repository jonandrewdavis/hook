extends RigidBody3D

# ques
# hinge join to the body, ragdoll

func _ready():
	print('head ready')

var captured_by = null

@rpc("any_peer", "call_local")
func get_hooked():
	$Timer.start()
	var playerId = multiplayer.get_remote_sender_id()
	for player in get_tree().get_nodes_in_group("Players"):
		if player.id == playerId:
			captured_by = player

func _physics_process(delta):
	if captured_by != null and global_position.distance_to(captured_by.global_position) > 3:
		var direction = global_position.direction_to(captured_by.global_position).normalized()
		var distance_factor = global_position.distance_to(captured_by.global_position)
		apply_force(direction * 20 * distance_factor / 10)
	elif captured_by != null:
		# reset
		$Timer.start()
		captured_by = null

func _on_timer_timeout():
	if multiplayer.is_server():
		queue_free()
	pass # Replace with function body.

func destroy():
	if multiplayer.is_server():
		queue_free()
