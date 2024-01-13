class_name Dead

extends State

func enter():
	player.HOOK.hide()
	player.DEATH_CAM.current = true	
	player.set_collision_layer_value(1, false)
	player.MODEL.play('death')
	player.MODEL.show()
	player.WEAPONS.hide()
	pass

# TODO: Move hook states into the actual FSM.
func update(_delta):
	if not (player.MODEL.ani.is_playing()):
		transition.emit("Idle")

func _input(_event):
	pass

func exit():
	player.CAMERA_CONTROLLER.current = true
	player.set_collision_layer_value(1, true)
	player.MODEL.hide()
	player.WEAPONS.show()
	player.HOOK.show()
	player.set_movement_speed("default")
	player.respawn()
