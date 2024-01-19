extends RigidBody3D

var shell = false
var Damage: int = 0
var Source: int

func _ready():
	if shell == true:
		$Timer.wait_time = 0.3
		$Timer.start()

func _on_body_entered(body):
	if body.is_in_group("Players") && body.has_method("Hit_Successful"):
		var hit_player = body.get_multiplayer_authority()
		# id to hit,
		# source, damage, position, rotation
		body.Hit_Successful.rpc_id(hit_player, Source, Damage, null, null)
		if multiplayer.is_server(): 
			if hit_player != Source:
				queue_free()
		return

	if body.is_in_group("Head") && body.has_method("Hit_Successful"):
		body.Hit_Successful(Source, Damage, null, global_position)
		if multiplayer.is_server(): 
			queue_free()
		return
	
	if multiplayer.is_server(): 
		queue_free()
		

func _on_timer_timeout():
	if multiplayer.is_server():	
		queue_free()
