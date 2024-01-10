extends RigidBody3D

var Damage: int = 0
var Source: int

func _on_body_entered(body):
	if body.is_in_group("Players") && body.has_method("Hit_Successful"):
		var hit_player = body.get_multiplayer_authority()
		# id to hit,
		# source, damage, position, rotation
		body.Hit_Successful.rpc_id(hit_player, Source, Damage, null, null)
	if multiplayer.is_server(): queue_free()

func _on_timer_timeout():
	if multiplayer.is_server():	queue_free()
