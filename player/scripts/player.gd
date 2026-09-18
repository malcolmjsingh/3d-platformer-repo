class_name Player extends CharacterBody3D

@onready var player: CharacterBody3D = $"."
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var state_machine: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")
@onready var model: Node3D = $guy
@onready var camera_pivot: Node3D = $cameraPivot
@onready var player_camera: Camera3D = $cameraPivot/playerCamera
@onready var low_ray: RayCast3D = $LowRay
@onready var high_ray: RayCast3D = $HighRay

@export var sensitivity: float = 0.005
@export var min_pitch: float = -80.0
@export var max_pitch: float = 80.0
var camera_rotation: Vector2

#general movement exports
@export var ACCEL = 0.4
@export var DEACCEL = 0.7
@export var TURNSPEED = 0.1
@export var CURRENT_MAX_SPEED = 6.0
@export var TRUE_MAX_SPEED = 10.0
@export var JUMP_VELOCITY = 6.0
@export var AIR_INPUT_ACCELERATION: float = 40.0
@export var AIR_NO_INPUT_DRAG: float = 40.0
@export var AIR_MOMENTUM_DECAY: float = 8.0 
@export var FLOOR_INPUT_ACCELERATION: float = 55.0
@export var FLOOR_NO_INPUT_DRAG: float = 75.0
@export var FLOOR_MOMENTUM_DECAY: float = 8.0 


#state and behavior specific exports

# wall jump
@export var WALL_JUMP_VERTICAL: float = 7.5
@export var WALL_JUMP_KICK: float = 6.0
@export var WALL_JUMP_AIR_INPUT_ACCELERATION: float = 25.0
@export var WALL_JUMP_AIR_NO_INPUT_DRAG: float = 5.0
@export var WALL_JUMP_AIR_MOMENTUM_DECAY: float = 8.0 

# diving
@export var DIVE_VERTICAL:float = 3.0
@export var DIVE_HORIZONTAL:float = 14.0
@export var DIVE_TURN_SPEED = 0.01

#crouch jump


#state and substate boolean exports
@export var isCrouching := false
@export var isSprinting := false # -> also unused
@export var isDiving := false # --> probably dont actualy need this because of the way the states are setup


func _physics_process(delta: float) -> void:
	# ---> Debug only
	
	# vector of where the camera is facing
	var cam_vector = -player_camera.global_transform.basis.z
	var cam_normalized_and_projected = Vector3(cam_vector.x, 0, cam_vector.z).normalized()
	DebugDraw3D.draw_arrow(1.5*Vector3.UP + player.position, 1.5*Vector3.UP + player.position + 2*cam_normalized_and_projected, Color.RED, 0.05)
	
	# vector of where the player character is facing
	var model_vector = model.global_transform.basis.z
	var model_normalized_and_projected = Vector3(model_vector.x, 0, model_vector.z).normalized()
	DebugDraw3D.draw_arrow(1.5*Vector3.UP + player.position, 1.5*Vector3.UP + player.position + 2*model_normalized_and_projected, Color.BLUE, 0.05)
	
	#vector of where the user is inputing
	var user_input_dir_2d := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var user_input_dir_3d := (player_camera.global_transform.basis * Vector3(user_input_dir_2d.x, 0, user_input_dir_2d.y)).normalized()
	var user_input_dir_3d_renormalized = Vector3(user_input_dir_3d.x, 0, user_input_dir_3d.z).normalized()
	DebugDraw3D.draw_arrow(1.5*Vector3.UP + player.position, 1.5*Vector3.UP + player.position + 2*user_input_dir_3d_renormalized, Color.GREEN, 0.05)
	
	#vector of player velocity
	DebugDraw3D.draw_arrow(1.5*Vector3.UP + player.position, 1.5*Vector3.UP + player.position + 2*player.velocity.normalized(), Color.YELLOW, 0.05)
	
	#keep rays matching model rotation
	
	low_ray.rotation.y = model.rotation.y
	high_ray.rotation.y = model.rotation.y
	
	if isCrouching:
		player.CURRENT_MAX_SPEED = 3.0
	else:
		if Input.is_action_pressed("sprint"):
			player.CURRENT_MAX_SPEED = 10.0
		else:
			player.CURRENT_MAX_SPEED = 6.0
	

#really bad orbit cam
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		camera_rotation.x -= event.relative.x * sensitivity
		camera_rotation.y -= event.relative.y * sensitivity
		camera_rotation.y = clamp(camera_rotation.y, deg_to_rad(min_pitch), deg_to_rad(max_pitch))
		camera_pivot.rotation.y = camera_rotation.x
		#camera_pivot.rotation.x = camera_rotation.y
