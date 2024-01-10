extends Node3D


@onready var LAVA_AREA = $LavaMesh/LavaArea

func _ready():
	pass

func _on_lava_area_body_entered(body):
	if body.is_in_group("Players"):
		body.respawn()
		return
	
	# todo: do skulls float in lava?
	if body.is_in_group('Target'):
		body.destroy()
		return
