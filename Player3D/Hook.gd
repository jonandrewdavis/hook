extends Node3D

@onready var player: CharacterBody3D = get_parent().get_parent().get_parent()
@onready var grapple_timer = $GrappleTimer

@onready var LOOKPOINT = $Lookpoint
@onready var GRAPPLECAST: RayCast3D = $GrappleCast
@onready var HOOKBODY = $HookMesh
@onready var LINE = $HookMesh/Arm
@onready var LINE_REMOTE = $HookMesh/ArmRemote
@onready var CLAW = $HookMesh/Claw
@onready var HAND_MODEL = $HookMesh/Claw/Open
@onready var FIST_MODEL = $HookMesh/Claw/Fist

@onready var CLAW_AREA = $HookMesh/Claw/ClawArea
@onready var CLAW_COLLISION = $HookMesh/Claw/ClawArea/ClawCollision

var HOOK_SPEED = 30
var HOOK_TIME = 1

enum STATE {IDLE, SEEKING, PULLING_SELF, PULLING_ENEMY}
var curr: STATE = STATE.IDLE

func _ready():
	reset()

func _process(_delta):
	match curr:
		STATE.SEEKING:
			seeking(_delta)
		STATE.PULLING_SELF:
			pulling_self()
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
	CLAW.global_position += GRAPPLECAST.global_transform.basis * Vector3(0, 0, -HOOK_SPEED) * delta
	line_trace()
	pass
	
func pulling_self():
	if Input.is_action_just_pressed("jump"):
		cancel_hook()
		await get_tree().create_timer(0.2).timeout
		player.air_jump += 1

	if player.global_position.y > CLAW.global_position.y + 0.5:
		player.gravity = 9.8
	else:
		player.gravity = -9.8
	if player.is_on_floor():
		player.velocity.y = 0.05
	
	line_trace()
		
	# ENDING CONDITION + Move the Player (self)	
	if CLAW.global_position.distance_to(player.transform.origin) > 2:
		player.transform.origin = lerp(player.transform.origin, CLAW.global_position, 0.005)
	else:
		cancel_hook()

var pulled_enemy


func pulling_enemy():
	line_trace()
	if Input.is_action_just_pressed("jump"):
		# TODO: if you cancel, you should let them go, issue a 
		# RPC to stop, where they are, and drop.
		cancel_hook()
	if pulled_enemy == null:
		return
	CLAW.global_position = Vector3(pulled_enemy.transform.origin.x, pulled_enemy.transform.origin.y + 1, pulled_enemy.transform.origin.z)
	if pulled_enemy.transform.origin.distance_to(player.transform.origin) < 3:
		cancel_hook()


# NOTE:

var aim_pos
var aim_rot

func launch_hook():
	player.gravity = 9.8
	# TODO: Only allow hook in idle state
	# if curr == STATE.IDLE: 
	$HookTimer.wait_time = HOOK_TIME
	$HookTimer.paused = false
	$HookTimer.start()
	CLAW.hide()
	
	aim_pos = GRAPPLECAST.global_position
	aim_rot = GRAPPLECAST.global_transform.basis

	CLAW.global_position = aim_pos
	CLAW.transform.basis = aim_rot
	CLAW.look_at(LOOKPOINT.global_position)
	curr = STATE.SEEKING
	
	await get_tree().create_timer(0.02).timeout
	CLAW.show()
	LINE.show()
	CLAW.set_scale(Vector3(1.3, 1.3, 1.3))
	CLAW_COLLISION.disabled = false
	hand()

func init():
	pass

func reset():
	pulled_enemy = null
	player.gravity = 9.8
	CLAW.top_level = false
	CLAW.position = Vector3.ZERO
	CLAW.look_at(LOOKPOINT.global_position)
	CLAW.set_scale(Vector3(0.2, 0.2, 0.2))
	LINE.visible = false
	if is_multiplayer_authority():
		LINE_REMOTE.visible = false
		LINE_REMOTE.set_scale(Vector3(0, 0, 0))
	CLAW_COLLISION.disabled = true
	HOOKBODY.look_at(LOOKPOINT.global_position)
	fist()
	if player.FSM != null:
		player.FSM.set_state("Idle")
	
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

func _on_hook_timer_timeout():
	# TODO: Explode, then cancel
	cancel_hook()
	pass # Replace with function body.

func fist():
	FIST_MODEL.show()
	HAND_MODEL.hide()

func hand():
	FIST_MODEL.hide()
	HAND_MODEL.show()

func _on_claw_area_body_entered(body):
	print('body ', body)
	
	if body == null:
		return
		
	if body.is_in_group("players") and body.get_multiplayer_authority() != get_multiplayer_authority():
		$HookTimer.paused = true
		call_deferred('disable_collision')
		curr = STATE.PULLING_ENEMY
		pulled_enemy = body
		body.get_hooked.rpc()
		fist()
		return
	
	# prevent self collisions
	if body.is_in_group("players"):
		return
		
	# TODO: Only allow collisions with a type of surface or layer, remove above check
	if body != null:
		curr = STATE.PULLING_SELF
		$HookTimer.paused = true
		call_deferred('disable_collision')
		CLAW.top_level = true
		CLAW.global_position = CLAW.position
		fist()
		player.FSM.set_state("Idle")
		return

func disable_collision():
	CLAW_COLLISION.disabled = true
