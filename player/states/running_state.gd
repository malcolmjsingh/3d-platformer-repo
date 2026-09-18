extends PlayerState

func enter(previous_state_path: String, data: Dictionary = {}) -> void:
	var animation_current_state = animation_state_machine.get_current_node()
	if not Input.is_action_pressed("crouch"):
		player.isCrouching = false
		PlayerSignalBus.substate_changed.emit("None")
		
	if player.isCrouching:
		if animation_current_state != "crouch_fwd_walk":
			animation_state_machine.travel("crouch_fwd_walk")
	else:
		if animation_current_state != "Ground":
			animation_state_machine.travel("Ground")
		animation_tree.set("parameters/Ground/blend_position", 0.0)
	
	

func update(delta: float) -> void:
	var user_input_dir_2d := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	#transition back to idle
	if not user_input_dir_2d and player.velocity.length() == 0:
		finished.emit(IDLE)
	
	#jump while running
	if Input.is_action_just_pressed("ui_accept") and player.is_on_floor():
		print("registered jump")
		finished.emit(JUMPING)
	
	if animation_state_machine.get_current_node() == "Ground":
		var floor_velocity = Vector3(player.velocity.x, 0, player.velocity.z)
		var speed = floor_velocity.length()
		animation_tree.set("parameters/Ground/blend_position", clamp(speed/player.TRUE_MAX_SPEED, 0.0, 1.0))
	
	if Input.is_action_pressed("crouch") and player.is_on_floor() and not player.isCrouching:
		PlayerSignalBus.substate_changed.emit("Crouch")
		player.isCrouching = true
		animation_state_machine.travel("crouch_fwd_walk")
	
	if Input.is_action_just_released("crouch") and player.isCrouching:
		PlayerSignalBus.substate_changed.emit("None")
		player.isCrouching = false
		animation_state_machine.travel("Ground")
	
	if Input.is_action_just_pressed("secondary"):
		if (low_ray.is_colliding() and not high_ray.is_colliding()):
			print("attemping to grab")

func physics_update(delta: float) -> void:
	if not player.is_on_floor():
		player.velocity += player.get_gravity() * delta
		if (player.velocity.y < 0):
			finished.emit(FALLING)
	
	var user_input_dir_2d := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var user_input_dir_3d := (player_camera.global_transform.basis * Vector3(user_input_dir_2d.x, 0, user_input_dir_2d.y)).normalized()
	var user_input_dir_3d_renormalized = Vector3(user_input_dir_3d.x, 0, user_input_dir_3d.z).normalized()
	
	var current_speed := Vector2(player.velocity.x, player.velocity.z).length()
	
	if user_input_dir_3d_renormalized:

		var input_angle := atan2(user_input_dir_3d_renormalized.x, user_input_dir_3d_renormalized.z)
		player_model.rotation.y = lerp_angle(player_model.rotation.y, input_angle, player.TURNSPEED)
		player_model.rotation.y = wrapf(player_model.rotation.y, -PI, PI)
		

		if current_speed < player.CURRENT_MAX_SPEED:
			current_speed = move_toward(current_speed, player.CURRENT_MAX_SPEED, player.FLOOR_INPUT_ACCELERATION * delta)
	else:
		current_speed = move_toward(current_speed, 0, player.FLOOR_NO_INPUT_DRAG * delta)
	
	if current_speed > player.CURRENT_MAX_SPEED:
		current_speed = move_toward(current_speed, player.CURRENT_MAX_SPEED, player.FLOOR_MOMENTUM_DECAY * delta)
	

	var model_forward := Vector3(sin(player_model.rotation.y), 0, cos(player_model.rotation.y)).normalized()
	
	player.velocity.x = model_forward.x * current_speed
	player.velocity.z = model_forward.z * current_speed
	
	player.move_and_slide()

func exit():
	pass
