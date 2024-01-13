class_name Idle

extends State

func enter():
	if player != null and player.MODEL != null:
		player.MODEL.get_node("AnimationPlayer").play("RESET")

func update(_delta):
	if player.velocity.length() > 0.0 and player.is_on_floor():
		transition.emit("Walking")
