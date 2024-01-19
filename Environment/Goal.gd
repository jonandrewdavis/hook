extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

# head
func _on_area_3d_body_entered(body):
	var scored_team = body.last_captured_by
	if scored_team == 'Blue':
		Store.set_state.rpc('blue_score', 1)
	elif scored_team == 'Red':
		Store.set_state.rpc('red_score', 1)
	body.destroy()
