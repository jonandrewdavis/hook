class_name Idle

extends State

func enter():
	if player.MODEL != null:
		player._speed = player.SPEED_DEFAULT
		player.MODEL.animation_player.play("EnemyArmature|EnemyArmature|EnemyArmature|Idle")

func update(_delta):
	if player.velocity.length() > 0.0 and player.is_on_floor():
		transition.emit("Walking")
