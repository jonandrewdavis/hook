class_name Busy

extends State

func enter():
	player.set_movement_speed("crouching")

func update(_delta):
	pass

func _input(_event):
	pass

func exit():
	player.set_movement_speed("default")
