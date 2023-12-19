class_name Idle

extends State

func enter():
	if player.MODEL != null:
		player._speed = player.SPEED_DEFAULT
		player.MODEL.get_node("AnimationPlayer").pause()

func update(_delta):
	if player.velocity.length() > 0.0 and player.is_on_floor():
		transition.emit("Walking")

func _input(_event):
	if Input.is_action_just_pressed("test"):	
		transition.emit('Stunned')
