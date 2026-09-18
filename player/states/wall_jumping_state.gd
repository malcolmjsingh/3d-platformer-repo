extends PlayerState

@export var wall_jump_vertical: float = 7.5
@export var wall_jump_kick: float = 12.0
@export var input_bias_factor: float = 0.4 # 0.0 is pure wall normal, 1.0 is pure input

func enter(_previous_state_path: String, data: Dictionary = {}) -> void:
	var wall_normal: Vector3 = data.get("wall_normal", Vector3.UP)
	var wall_normal_xz := Vector3(wall_normal.x, 0.0, wall_normal.z).normalized()
	var launch_dir := wall_normal_xz
	
	# 1. Get Camera-Relative Input
	var input_2d := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input_2d != Vector2.ZERO:
		var input_3d := (player_camera.global_transform.basis * Vector3(input_2d.x, 0, input_2d.y))
		input_3d.y = 0
		input_3d = input_3d.normalized()
		
		# 2. Check if the input is pushing into the wall
		var wall_dot := input_3d.dot(wall_normal_xz)
		if wall_dot < 0:
			# Godot's bounce() mirrors the vector across the normal
			# e.g., holding Forward-Left into a Left wall converts the input to Forward-Right
			input_3d = input_3d.bounce(wall_normal_xz)
		
		# 3. Blend the wall normal with the (now safely outward) input vector
		launch_dir = wall_normal_xz.lerp(input_3d, input_bias_factor).normalized()
	
	# 4. Snap the model to face the new blended trajectory
	var launch_angle := atan2(launch_dir.x, launch_dir.z)
	player_model.rotation.y = launch_angle
	player_model.rotation.y = wrapf(player_model.rotation.y, -PI, PI)
	
	# 5. Apply the initial kick vector based on the blended direction
	player.velocity.y = wall_jump_vertical
	player.velocity.x = launch_dir.x * wall_jump_kick
	player.velocity.z = launch_dir.z * wall_jump_kick
	
	if animation_state_machine.get_current_node() != "Jump":
		animation_state_machine.travel("Jump")

func physics_update(delta: float) -> void:
	if not player.is_on_floor():
		player.velocity += player.get_gravity() * delta
		if player.velocity.y < 0:
			finished.emit(FALLING)

	var input_2d := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var input_3d := (player_camera.global_transform.basis * Vector3(input_2d.x, 0, input_2d.y))
	input_3d.y = 0
	input_3d = input_3d.normalized()

	var current_speed := Vector2(player.velocity.x, player.velocity.z).length()

	# 4. Handle Rotation and Acceleration
	if input_3d != Vector3.ZERO:
		# Rotate the model toward the input
		var input_angle := atan2(input_3d.x, input_3d.z)
		player_model.rotation.y = lerp_angle(player_model.rotation.y, input_angle, player.TURNSPEED)
		player_model.rotation.y = wrapf(player_model.rotation.y, -PI, PI)
		
		# Accelerate up to normal max speed if we are moving too slow
		if current_speed < player.CURRENT_MAX_SPEED:
			current_speed = move_toward(current_speed, player.CURRENT_MAX_SPEED, player.WALL_JUMP_AIR_INPUT_ACCELERATION * delta)
	else:
		# Apply air drag if the player lets go of the stick
		current_speed = move_toward(current_speed, 0, player.WALL_JUMP_AIR_NO_INPUT_DRAG * delta)

	# 5. Decay Overshooting Momentum
	# If the wall kick made us faster than standard top speed, bleed it off smoothly
	if current_speed > player.CURRENT_MAX_SPEED:
		current_speed = move_toward(current_speed, player.CURRENT_MAX_SPEED, player.WALL_JUMP_AIR_MOMENTUM_DECAY * delta)

	# 6. Apply Speed Strictly to Model Forward
	var model_forward := Vector3(sin(player_model.rotation.y), 0, cos(player_model.rotation.y)).normalized()
	
	player.velocity.x = model_forward.x * current_speed
	player.velocity.z = model_forward.z * current_speed

	player.move_and_slide()
