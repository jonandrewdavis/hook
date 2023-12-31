extends Node3D

@onready var animation_player = $AnimationPlayer
@onready var barrel = $RayCast3D

func speed_up():
	animation_player.speed_scale = 4
	$GPUParticles3D.emitting = true
	$GPUParticles3D2.emitting = true
	await get_tree().create_timer(5).timeout
	$GPUParticles3D.emitting = true
	$GPUParticles3D2.emitting = true
	animation_player.speed_scale = 1
	pass
