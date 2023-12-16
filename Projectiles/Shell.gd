extends Node3D

const SPEED = 120.0

@onready var mesh = $MeshInstance3D
@onready var ray = $RayCast3D
@onready var particles = $GPUParticles3D

func _ready():
	await $Timer.timeout
	if multiplayer.is_server():
		queue_free()

func _process(delta):
	position += transform.basis * Vector3(0, 0, -SPEED) * delta
	if ray.is_colliding():
		mesh.visible = false
		particles.emitting = true
		await get_tree().create_timer(0.5).timeout
		if multiplayer.is_server():
			queue_free()
