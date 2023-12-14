extends Area3D



func _on_body_entered(body):
	body.damage.emit(1000)
