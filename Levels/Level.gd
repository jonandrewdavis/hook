extends Node3D

@onready var LAVA_AREA = $LavaMesh/LavaArea
@onready var LEVEL_CAM = $CamHolder/LevelCam

func _ready():
	pass
	
func play_goal_animation():
	if multiplayer.is_server():
		$GoalsAnimation.play('goals')

func _on_lava_area_body_entered(body):
	if body.is_in_group("Players"): 
		if multiplayer.is_server() and  body.is_in_group('Players'):
			body.toggle_damage_over_time.rpc(60)
		return 
		
	if body.is_in_group('Head'):
		body.destroy()
		return

func _on_goal_protection_body_entered(body):
	if multiplayer.is_server() and body.is_in_group('Players'):
		# print('enter',  get_multiplayer_authority(), 'me: ', body.get_multiplayer_authority())
		body.toggle_damage_over_time.rpc(13)
	pass # Replace with function body.

func _on_goal_protection_body_exited(body):
	if multiplayer.is_server() and  body.is_in_group('Players'):
		body.toggle_damage_over_time.rpc(0)
	pass # Replace with function body.

func _on_lava_area_body_exited(body):
	if multiplayer.is_server() and  body.is_in_group('Players'):
		body.toggle_damage_over_time.rpc(0)
	pass # Replace with function body.













# home


func _on_red_home_body_entered(body):
	if multiplayer.is_server() and body.is_in_group('Players') and body.TEAM == 'Blue':
		body.toggle_damage_over_time.rpc(2)
	pass # Replace with function body.


func _on_red_home_body_exited(body):
	if multiplayer.is_server() and body.is_in_group('Players') and body.TEAM == 'Blue':
		body.toggle_damage_over_time.rpc(0)
	pass # Replace with function body.


# Blue hurts red players
#
func _on_blue_home_body_entered(body):
	if multiplayer.is_server() and body.is_in_group('Players') and body.TEAM == 'Red':
		body.toggle_damage_over_time.rpc(2)
	pass # Replace with function body.


func _on_blue_home_body_exited(body):
	if multiplayer.is_server() and body.is_in_group('Players') and body.TEAM == 'Red':
		body.toggle_damage_over_time.rpc(0)
	pass # Replace with function body.
