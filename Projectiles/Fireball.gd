extends Node2D

var direction: Vector2 = Vector2.ZERO
var speed = 200

func _ready():
	if multiplayer.is_server():
		await get_tree().create_timer(4).timeout
		queue_free()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
