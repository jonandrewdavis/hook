extends State


func enter():
	player.set_movement_speed("crouching")

func update(_delta):
	pass

func _input(event):
	pass

func exit():
	player.set_movement_speed("default")
