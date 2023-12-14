extends State

func enter():
	player._speed = player.SPEED_DEFAULT

func update(_delta):
	if player.velocity.length() == 0.0:
		transition.emit("Idle")

func _input(event):
	if event.is_action_pressed('sprint'):
		transition.emit('Sprint')
