extends Node3D

@onready var ani =  $AnimationPlayer

# shortcut. probably shouldn't use
func play(string_name):
	ani.play(string_name)
