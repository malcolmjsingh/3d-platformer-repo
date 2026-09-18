extends PlayerState

func enter(previous_state_path: String, data: Dictionary = {}) -> void:
	var animation_current_state = animation_state_machine.get_current_node()
	if player.isCrouching:
		if animation_current_state != "long_jump":
			animation_state_machine.travel("long_jump")
		player.velocity.y = player.JUMP_VELOCITY * 0.7
		var new_model_forward = Vector3(sin(player_model.rotation.y), 0, cos(player_model.rotation.y)).normalized()
		player.velocity.x = new_model_forward.x * 30
		player.velocity.z = new_model_forward.z * 30
	else:
		if animation_current_state != "Jump":
			animation_state_machine.travel("Jump")
		player.velocity.y = player.JUMP_VELOCITY

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
			current_speed = move_toward(current_speed, player.CURRENT_MAX_SPEED, player.AIR_INPUT_ACCELERATION * delta)
	else:
		current_speed = move_toward(current_speed, 0, player.AIR_NO_INPUT_DRAG * delta)
	
	if current_speed > player.CURRENT_MAX_SPEED:
		current_speed = move_toward(current_speed, player.CURRENT_MAX_SPEED, player.AIR_MOMENTUM_DECAY * delta)
	

	var model_forward := Vector3(sin(player_model.rotation.y), 0, cos(player_model.rotation.y)).normalized()
	
	player.velocity.x = model_forward.x * current_speed
	player.velocity.z = model_forward.z * current_speed
	
	player.move_and_slide()

func update(_delta: float) -> void:
	if Input.is_action_just_released("crouch") and player.isCrouching:
		PlayerSignalBus.substate_changed.emit("None")
		player.isCrouching = false
	
	
	if Input.is_action_just_pressed("secondary"):
		if (low_ray.is_colliding() and not high_ray.is_colliding()):
			print("attemping to grab")
		else:
			finished.emit(DIVING)


func exit():
	pass
