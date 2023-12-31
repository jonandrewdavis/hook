extends Node3D


@onready var LAVA_AREA = $LavaMesh/LavaArea



func _on_lava_area_body_entered(body):
	if body.is_in_group("players"):
		body.respawn()
		body.gun.speed_up()
		pass # Replace with function body.
