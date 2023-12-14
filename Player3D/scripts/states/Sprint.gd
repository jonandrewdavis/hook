class_name Sprint extends State

@export var ANIMATION : AnimationPlayer
@export var TOP_ANIMATION_SPEED: float = 1.6

func enter():
	player._speed = player.SPEED_SPRINTING

func update(_delta):
	pass

func _input(event):
	if event.is_action_released('sprint'):
		transition.emit('Walking')
