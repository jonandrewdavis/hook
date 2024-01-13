extends Node3D

@onready var ani =  $AnimationPlayer
@onready var HEAD = $character_skeleton_mage_body/character_skeleton_mage_head

# shortcut. probably shouldn't use
func play(string_name):
	ani.play(string_name)
