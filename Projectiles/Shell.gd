class_name Shell

extends Node3D

var SPEED = 60.0

@onready var BONE_FINGER = $BoneFinger 
@onready var ray = $RayCast3D
@onready var particles = $GPUParticles3D
@onready var SHELL_HURTBOX = $ShellHurtBox
@onready var SHELL_COLLISION = $ShellHurtBox/ShellHurtCollision

var is_burst = true
var burst_time = 0.19
var source = null

# TODO: Put all bullet collisions and terrain conditions on different layers.

func _ready():
	set_process(get_multiplayer_authority() == multiplayer.get_unique_id())
	if is_burst == true:
		$Timer.wait_time = burst_time
		$Timer.start()
	else:
		SPEED = SPEED * 2
		$Timer.start()
	await $Timer.timeout
	if multiplayer.is_server():
		queue_free()
		
# TODO: Bullet drop
func _process(delta):
	position += transform.basis * Vector3(0, 0, -SPEED) * delta
	if ray.is_colliding():
		register_hit_and_destroy_self()
	# this is environmental register_hit
	# note: Rays don't collide with themseleves, so shotgun spread doesn't error out badly with these

#
func register_hit_and_destroy_self():
	pass
	
	
# this is the player register_hit_and_destroy_self
func _on_shell_hurt_box_area_entered(area):
	if multiplayer.is_server():
		if area.name == 'HurtboxHead' or area.name == 'HurtboxBody':
			# prevents self harm
			var hurtbox_player_source = area.get_multiplayer_authority()
			if hurtbox_player_source != source and source != null:
				# TODO: Send damage value over from this shell.
				# Technically this could be a server call... independent of a player
				# We tell the damage call, who to damage, from who, and how much
				call_damage.rpc(hurtbox_player_source, source)
				register_hit_and_destroy_self()

@rpc("authority", 'call_local')
func call_damage(hurt_id, source_id):
	# print("Headshot detected on: ", Store.store.players[hurt_id].nickname, 'from: ', Store.store.players[source_id].nickname)
	var hurt_player = get_parent().get_node(str(hurt_id))
	# TODO: Proper damage calc
	hurt_player.take_damage(10, source_id)

