extends Node3D

# TODO: Redo hook as a physics body.

var DEFAULT_HOOK_HEALTH: int = 17
var hook_health = DEFAULT_HOOK_HEALTH

@onready var player: Player = get_parent().get_parent().get_parent()
@onready var GRAPPLE_TIMER = $GrappleTimer

@onready var LOOKPOINT = $Lookpoint
@onready var GRAPPLECAST: RayCast3D = $GrappleCast
@onready var HOOKBODY = $HookMesh
@onready var LINE = $HookMesh/Arm
@onready var LINE_REMOTE = $HookMesh/ArmRemote
@onready var CLAW = $HookMesh/Claw
@onready var HAND_MODEL = $HookMesh/Claw/Open
@onready var FIST_MODEL = $HookMesh/Claw/Fist

@onready var CLAW_AREA: Area3D = $HookMesh/Claw/ClawArea
@onready var CLAW_COLLISION: CollisionShape3D = $HookMesh/Claw/ClawArea/ClawCollision

@onready var HOOK_SPEED_DEFAULT = 30
@onready var CLAW_COLLISION_EXPANDED: Vector3 = Vector3(2, 2, 2)

var HOOK_SPEED = HOOK_SPEED_DEFAULT
var HOOK_TIME = 1

enum STATE {IDLE, SEEKING, PULLING_SELF, PULLING_ENEMY}
var curr: STATE = STATE.IDLE
var is_on_cooldown = false

func _ready():
	reset()

func _process(_delta):
	match curr:
		STATE.SEEKING:
			seeking(_delta)
		STATE.PULLING_SELF:
			pulling_self(_delta)
		STATE.PULLING_ENEMY:
			pulling_enemy()
		_:
			pass

# NOTE: It is possible to seek and aim at the same time using:
# CLAW.top_level = false
# CLAW.global_position += GRAPPLECAST.global_transform.basis * Vector3(0, 0, -20) * delta
# NOTE: This is the current paradigm.

# CONS: at long distances, the aim is strong and if you're falling the grapple falls with you
# PROS: Better control of the hook via strafing, and when falling you can predict it based on gravity

# TODO: Determine if top level is better, this is like launching a bullet, it goes to where pointed.
# Might be better balanced.

func seeking(delta):
	if Input.is_action_just_pressed("hook") and CLAW_COLLISION.scale.x < 3  and $HookTimer.time_left < 0.9:
		fist()
		CLAW_COLLISION.set_scale(CLAW_COLLISION_EXPANDED)
		HOOK_SPEED = 22

		
	if $HookTimer.time_left < 0.15 and CLAW_COLLISION.scale.x < 3:
		CLAW_COLLISION.set_scale(CLAW_COLLISION_EXPANDED)
			
	line_trace()
	CLAW.global_position += GRAPPLECAST.global_transform.basis * Vector3(0, 0, -HOOK_SPEED) * delta	
	
var inverse = false


# TODO: Windlands like "swinging using WASD", but essentailly, you "let out line", when you are inputting, and in neutral it reels in?
# TODO: Go play windlsands? stick

# need to find a way to gently pull the player back into the domain, then resume listening to input
# TODO: WASD.
# TODO: Control should "let out line"
# TODO: If you are holding forward and below: y, let out slack, and apply a little gravity (up to 30m!, at which you should be 0 grav, no effect)
# TODO: If you are holding nothing, reel in like normal, Lerp and gravity. 
func pulling_self(_delta):
	var current_pull_distance = player.transform.origin.distance_to(CLAW.global_position)
	line_trace()

	if Input.is_action_just_pressed("jump"):
		cancel_hook()
		provide_air_jump()
		return

	if player.is_on_floor():
		player.velocity.y = 0.05
	
	var move_forward = false
	if Input.is_action_pressed("move_forward") and move_forward == true:
		if player.global_position.y > CLAW.global_position.y + 0.5:
			# above y
			# player.transform.origin = lerp(player.transform.origin, CLAW.global_position, 0.0005)
			player.gravity = 9.8 * 1.2
			player._speed = player.SPEED_DEFAULT * 0.2
			if abs(current_pull_distance) < abs(max_hook_distance - 1):
				player.transform.origin = lerp(player.transform.origin, CLAW.global_position, 0.0006)
		else:
			# below y, add some gravity and forward momentum to swing
			# add a little extra gravity on FORWARD swing and less speed forward
			if abs(current_pull_distance) < abs(max_hook_distance - 1):
				player._speed = player.SPEED_DEFAULT * 2.4
				player.gravity = 9.8 * 1.2
			else:
				#below y, but out of bounds, add some bounce back (coerce back)
				player.transform.origin = lerp(player.transform.origin, CLAW.global_position, 0.0012)
				player._speed = player.SPEED_DEFAULT * 1.2
				player.gravity = -9.8 * 1.4
				#extra speed at bounce bottom
			# below y, general/default
	else:
		if player.global_position.y > CLAW.global_position.y + 0.5:
			if player.global_position.y > CLAW.global_position.y + 2:
				# when we're high up, gravity does a lot of work, so less lerp
				player.transform.origin = lerp(player.transform.origin, CLAW.global_position, 0.002)
			else:
				player.transform.origin = lerp(player.transform.origin, CLAW.global_position, 0.005)
			player.gravity = 9.8
		else:
			player.transform.origin = lerp(player.transform.origin, CLAW.global_position, 0.005)
			player.gravity = -9.8

	# ENDING CONDITION:
	if current_pull_distance < 2:
		cancel_hook()

func provide_air_jump():
	await get_tree().create_timer(0.2).timeout
	player.air_jump += 1

var pulled_enemy

func pulling_enemy():
	line_trace()
	if Input.is_action_just_pressed("jump"):
		# TODO: if you cancel, you should let them go, issue a 
		# RPC to stop, where they are, and drop.
		cancel_hook()
	if pulled_enemy == null:
		return
	CLAW.global_position = Vector3(pulled_enemy.transform.origin.x, pulled_enemy.transform.origin.y + 0.5, pulled_enemy.transform.origin.z)
	if pulled_enemy.transform.origin.distance_to(player.transform.origin) < 3:
		cancel_hook()

func move_in_fly(_delta):
	pass
	#var direction = update_direction()
	#var player_camera_dir = Vector3(-player.global_transform.basis.z.normalized().x, -player.CAMERA_CONTROLLER.transform.basis.z.normalized().y, -player.global_transform.basis.z.normalized().z) 
	# player.velocity = player_camera_dir * player._speed * 1.2
	# player.move_and_slide()

func update_direction():
	var dir = Vector3()
	if Input.is_action_pressed("move_forward"):
		dir += player.transform.basis.z
	if Input.is_action_pressed("move_backward"):
		dir += Vector3.BACK
	if Input.is_action_pressed("move_right"):
		dir += Vector3.RIGHT
	if Input.is_action_pressed("move_left"):
		dir += Vector3.LEFT
	if dir == Vector3.ZERO:
		player.velocity = Vector3.ZERO

	return dir.normalized()
	

func move_in_arc():
	# We need to "add  force", apply on every tick while "swinging"
	# Using the pendulum equation
	# "All we need to do is use the dot product of the players location",
	# "minus the point we're swinging from"
	# "then multiply this by the normalized direction vector of between these points
	# "and then multiply that result by -2"
	# "ut all the code is really doing is applying a corrective force - using the dot product method I mention in the video, this method also has the bonus of being adaptive to any other velocity added, so its quite versatile for collisions and force correction. 
	# The math for this is simple enough - just get the dot product of the players velocity and the distance to the attach point * the direction vector between the player and the attach point"
	
	var dot_product = player.velocity.dot(player.transform.origin - CLAW.global_position)
	var dir = player.transform.origin.direction_to(CLAW.global_position).normalized()
	var result = dot_product * dir * -2
	player.gravity = 9.8

	player.velocity.y = move_toward(player.velocity.y, result.y, player.ACCELERATION)
	player.velocity.z = move_toward(player.velocity.z, Vector3.FORWARD.z, player.ACCELERATION)

	result = Vector3.ZERO
	dot_product = Vector3.ZERO

	player.move_and_slide()


var aim_pos
var aim_rot

func launch_hook():
	is_on_cooldown = true
	CLAW_COLLISION.set_scale(Vector3(0.3,0.3,0.3))
	CLAW_COLLISION.disabled = true	
	# CLAW_COLLISION.set_scale(Vector3(1,1,1))
	HOOK_SPEED = HOOK_SPEED_DEFAULT
	player.gravity = 9.8
	# TODO: Only allow hook in idle state
	# if curr == STATE.IDLE: 
	$HookTimer.wait_time = HOOK_TIME
	$HookTimer.paused = false
	$HookTimer.start()
	
	aim_pos = GRAPPLECAST.global_position
	aim_rot = GRAPPLECAST.global_transform.basis

	CLAW.global_position = aim_pos
	CLAW.transform.basis = aim_rot
	CLAW.look_at(LOOKPOINT.global_position)
	curr = STATE.SEEKING
	CLAW.show()
	LINE.show()
	# We mess with scale instead of collision to allow closer, accurate hooks.
	await get_tree().create_timer(0.03).timeout
	# Only "Expand" the hook if we're in motion (unpaused), otherwise the scale blacks out the playerview
	if $HookTimer.paused == false:
		CLAW_COLLISION.disabled = false	
		CLAW_COLLISION.set_scale(Vector3(0.8,0.8,0.8))
		hand()

	await get_tree().create_timer(0.3).timeout
	# Only "Expand" the hook if we're in motion (unpaused), otherwise the scale blacks out the playerview
	if $HookTimer.paused == false:
		CLAW_COLLISION.set_scale(Vector3(1.3,1.3,1.3))
		hand()


func init():
	pass

func reset():
	call_deferred('disable_collision')
	hook_health = DEFAULT_HOOK_HEALTH
	pulled_enemy = null
	player.gravity = 9.8
	CLAW.top_level = false
	CLAW.position = Vector3.ZERO
	CLAW.look_at(LOOKPOINT.global_position)
	CLAW.set_scale(Vector3(0.33, 0.33, 0.33))
	if player.HOOK_CHARGES != null and player.HOOK_CHARGES > 0: unhide_hook()
	else: hide_hook()
	
	LINE.visible = false
	HOOK_SPEED = HOOK_SPEED_DEFAULT
	FIST_MODEL.visible = true
	FIST_MODEL.transform.basis = Basis.from_euler(Vector3.ZERO)
	if is_multiplayer_authority():
		LINE_REMOTE.visible = false
		LINE_REMOTE.set_scale(Vector3(0, 0, 0))
	HOOKBODY.look_at(LOOKPOINT.global_position)
	fist()
	if player.FSM != null:
		player.FSM.set_state("Idle")

func ready_hook():
	pulled_enemy = null
	CLAW.top_level = false
	CLAW.position = Vector3.ZERO
	CLAW.look_at(LOOKPOINT.global_position)
	CLAW.set_scale(Vector3(0.33, 0.33, 0.33))
	unhide_hook()
	LINE.visible = false
	HOOK_SPEED = HOOK_SPEED_DEFAULT
	FIST_MODEL.visible = true
	FIST_MODEL.transform.basis = Basis.from_euler(Vector3.ZERO)
	if is_multiplayer_authority():
		LINE_REMOTE.visible = false
		LINE_REMOTE.set_scale(Vector3(0, 0, 0))
	call_deferred('disable_collision')
	HOOKBODY.look_at(LOOKPOINT.global_position)
	fist()

var line_point_distance

func line_trace():
	if CLAW.global_position != HOOKBODY.global_position:
		HOOKBODY.look_at(CLAW.global_position)
	line_point_distance = player.transform.origin.distance_to(CLAW.global_position)
	LINE.set_scale(Vector3(1.15, 1.15, line_point_distance / 1.25))
	LINE_REMOTE.set_scale(Vector3(1.9, 1.9, line_point_distance * 1.25))
	# LINE.position = Vector3(0, 0, line_point_distance)
	
func cancel_hook():
	curr = STATE.IDLE
	reset()
	is_on_cooldown = true
	$Cooldown.start()
	
func _on_hook_timer_timeout():
	# TODO: Explode, then cancel
	CLAW_COLLISION.set_scale(CLAW_COLLISION_EXPANDED)
	await get_tree().create_timer(0.15).timeout
	if curr == STATE.SEEKING:
		cancel_hook()

func fist():
	FIST_MODEL.show()
	HAND_MODEL.hide()

func hand():
	FIST_MODEL.hide()
	HAND_MODEL.show()

func _on_claw_area_body_entered(body):
	if not curr == STATE.SEEKING:
		return
	# this prevents claw from being called from peers.
	if not is_multiplayer_authority():
		return
	if body == null:
		return
	
	if body.is_in_group("Bullet"):
		if body.Source != get_multiplayer_authority():
			take_hook_damage.rpc(body.Source, body.Damage)
		return
	
	# All targets can be grabbed.
	if body.is_in_group("Target"):
		if body.is_in_group("Players") and body.get_multiplayer_authority() != get_multiplayer_authority():
			if player.my_team_ids.find(body.id) == -1:
				hook_player(body)
		elif body.is_in_group("Head"):
			hook_player(body)
		return		
	# TODO: Should move along/move & slide along the floor.
	if body.is_in_group("SlowHook"):
		HOOK_SPEED = 2
		return

	# IgnoreHook "group" disallows terrain hooking.
	if not body.is_in_group("IgnoreHook"):
		hook_terrain(body)
		return

func hook_player(body):
	player.AUDIO.play('connect')	
	$HookTimer.paused = true
	call_deferred('disable_collision')
	curr = STATE.PULLING_ENEMY
	pulled_enemy = body
	body.get_hooked.rpc()
	fist()
	rotate_hand()

var max_hook_distance

func hook_terrain(_body):
	player.AUDIO.play('connect')
	curr = STATE.PULLING_SELF
	$HookTimer.paused = true
	# THIS ALLOWS DEATH OF HOOK
	# call_deferred('disable_collision')
	CLAW.top_level = true
	CLAW.global_position = CLAW.position
	max_hook_distance = player.transform.origin.distance_to(CLAW.global_position) 
	fist()
	rotate_hand()
	# If you're wrangling the camera, wait a second before restoring input or you will swing wildly.
	await get_tree().create_timer(0.3).timeout
	player.FSM.set_state("Idle")

func disable_collision():
	CLAW_COLLISION.disabled = true

func hide_hook():
	$HookMesh/Claw/Fist/FistModel.visible = false

func unhide_hook():
	$HookMesh/Claw/Fist/FistModel.visible = true
	
func reel_in():
	inverse = true

func _on_cooldown_timeout():
	is_on_cooldown = false
	
func rotate_hand():
	var test_rotation = Vector3(0.0,0.0, 0.15)
	FIST_MODEL.transform.basis = Basis.from_euler(test_rotation)

func _on_grapple_timer_timeout():
	if curr == STATE.PULLING_SELF:
		blink = 3
		$BlinkTimer.start()

var blink = 3

func _on_blink_timer_timeout():
	if curr == STATE.PULLING_SELF and blink > 0:
		blink -= 1
		$BlinkTimer.start()
	if curr == STATE.PULLING_SELF and blink == 0: 
		cancel_hook()

@rpc('any_peer', "call_local")
func take_hook_damage(Source, Damage):
	if Source != null:
		player.last_damage_source = Source
		if hook_health - Damage <= 0:
			cancel_hook()
		else:
			hook_health -= Damage
	
#@rpc("any_peer", "call_local")
#func Hit_Successful(Source, Damage, _Direction, _Position):
	## print('Hit Successful Called on Player:', get_multiplayer_authority(), ': ', Damage, 'from: ', Source)
	## This check effectively prevents self damage.
	#if Source != get_multiplayer_authority():  
		#take_hook_damage(Source, Damage)

func _on_hook_hurt_box_body_entered(body):
	if body.is_in_group("Bullet"):
		if body.Source != get_multiplayer_authority():
			if player.my_team_ids.find(body.Source) == -1:
				take_hook_damage.rpc(body.Source, body.Damage)
		return
