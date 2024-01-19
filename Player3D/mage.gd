extends Node3D

@onready var ani =  $AnimationPlayer
@onready var HEAD = $character_skeleton_mage_body/character_skeleton_mage_head

@onready var MESH_BLUE = $character_skeleton_mage_body/MESH_BLUE
@onready var MESH_RED = $character_skeleton_mage_body/MESH_RED

# shortcut. probably shouldn't use
func play(string_name):
	ani.play(string_name)
