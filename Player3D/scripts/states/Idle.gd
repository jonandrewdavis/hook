class_name Idle

extends State

func update(_delta):
	if player.velocity.length() > 0.0 and player.is_on_floor():
		transition.emit("Walking")
