class_name Sprint 

extends State

@export var ANIMATION : AnimationPlayer
@export var TOP_ANIMATION_SPEED: float = 1.6

func enter():
	player._speed = player.SPEED_SPRINTING
	player.MODEL.get_node("AnimationPlayer").play("run")
	
func _input(_event):
	pass
