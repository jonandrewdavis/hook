extends State

func enter():
	player._speed = player.SPEED_DEFAULT
	player.MODEL.get_node("AnimationPlayer").play("run")

func update(_delta):
	if player.velocity.length() == 0.0:
		transition.emit("Idle")

func _input(event):
	pass
