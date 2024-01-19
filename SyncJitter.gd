extends MultiplayerSynchronizer
class_name PhysicsSynchronizer
@export var sync_bstate_array : Array = \
	[0, Vector3.ZERO, Quaternion.IDENTITY, Vector3.ZERO, Vector3.ZERO]

@onready var sync_object : RigidBody3D = get_parent()
@onready var body_state : PhysicsDirectBodyState3D = \
	PhysicsServer3D.body_get_direct_state( sync_object.get_rid() )

var frame : int = 0
var last_frame : int = 0

enum { 
	FRAME,
	ORIGIN,
	QUAT, # the quaternion is used for an optimized rotation state
	LIN_VEL,
	ANG_VEL,
}


#copy state to array
func get_state( state, array ):
	array[ORIGIN] = state.transform.origin
	array[QUAT] = state.transform.basis.get_rotation_quaternion()
	array[LIN_VEL] = state.linear_velocity
	array[ANG_VEL] = state.angular_velocity


#copy array to state
func set_state( array, state ):
	state.transform.origin = array[ORIGIN]
	state.transform.basis = Basis( array[QUAT] )
	state.linear_velocity = array[LIN_VEL]
	state.angular_velocity = array[ANG_VEL]


func get_physics_body_info():
	# server copy for sync
	get_state( body_state, sync_bstate_array )


func set_physics_body_info():
	# client rpc set from server
	set_state( sync_bstate_array, body_state )


func _physics_process(_delta):
	if is_multiplayer_authority() and sync_object.visible:
		frame += 1
		sync_bstate_array[FRAME] = frame
		get_physics_body_info()


# make sure to wire the "synchronized" signal to this function
func _on_synchronized():
	correct_error()
	# is this necessary?
	if is_previouse_frame():
		return
	set_physics_body_info()

#  very basic network jitter reduction
func correct_error():
	var diff :Vector3= body_state.transform.origin - sync_bstate_array[ORIGIN]
#	print(name,": diff origin ", diff.length())
	# correct minor error, but snap to incoming state if too far from reality
	if diff.length() < 3.0:
		sync_bstate_array[ORIGIN] = body_state.transform.origin.lerp(sync_bstate_array[ORIGIN],0.05)

func is_previouse_frame() -> bool:
	if sync_bstate_array[FRAME] <= last_frame:
		return true
	else:
		last_frame = sync_bstate_array[FRAME]
		return false
