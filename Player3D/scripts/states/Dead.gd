class_name Dead

extends State

func enter():
	player.HOOK.hide()
	player.DEATH_CAM.current = true	
	player.set_collision_layer_value(1, false)
	player.set_collision_mask_value(1, false)
	player.set_collision_mask_value(24, false)
	player.set_collision_layer_value(24, false)
	player.MODEL.play('death')
	player.MODEL.show()
	player.WEAPONS.hide()
	player.invincible = true
	player.NAMELABEL.visible = false

# TODO: Move hook states into the actual FSM.
func update(_delta):
	if is_multiplayer_authority():
		if not (player.MODEL.ani.is_playing()):
			transition.emit("Idle")

func _input(_event):
	pass

func exit():
	player.CAMERA_CONTROLLER.current = true
	player.MODEL.hide()
	player.WEAPONS.show()
	player.HOOK.show()
	player.set_movement_speed("default")
	player.respawn()
	player.NAMELABEL.visible = true
	await get_tree().create_timer(1).timeout
	player.invincible = false

