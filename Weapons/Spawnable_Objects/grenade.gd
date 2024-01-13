extends RigidBody3D

var Damage: int
@export var Explosion: PackedScene


func _on_body_entered(_body):
	Explode()
	queue_free()
	

func _on_timer_timeout():
	Explode()
	queue_free()

func Explode():
	var ex = Explosion.instantiate()
	ex.set_global_transform(get_global_transform())
	var world = get_tree().get_root().get_child(0)
	world.add_child(ex)
	ex.Damage = Damage


