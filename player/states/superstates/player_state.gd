class_name PlayerState extends State

const IDLE = "Idle"
const RUNNING = "Running"
const FALLING = "Falling"
const JUMPING = "Jumping"
const DIVING = "Diving"
const SPINNING = "Spinning"
const WALLJUMPING = "WallJumping"
const GRABBINGLEDGE = "GrabbingLedge"

var player: Player
var player_camera: Camera3D
var player_model: Node3D
var player_actual_mesh: MeshInstance3D
var low_ray: RayCast3D
var high_ray: RayCast3D

var animation_tree: AnimationTree
var animation_state_machine: AnimationNodeStateMachinePlayback


func _ready() -> void:
	await owner.ready
	player = owner as Player
	player_camera = owner.get_node("cameraPivot").get_node("playerCamera") as Camera3D
	player_model = owner.get_node("guy") as Node3D
	player_actual_mesh = owner.get_node("guy").get_node("Armature").get_node("Skeleton3D").get_node("body") as MeshInstance3D
	low_ray = owner.get_node("LowRay")
	high_ray = owner.get_node("HighRay")
	animation_tree = owner.get_node("AnimationTree")
	animation_state_machine = animation_tree.get("parameters/playback")
	assert(player != null, "The PlayerState state type must be used only in the player scene. It needs the owner to be a Player node.")
