extends PlayerState
@onready var dive_timer: Timer = $DiveTimer
var isActionable := false


enum DIVESUBSTATE {INAIR, ONFLOOR, GETUP}
var current_dive_state: DIVESUBSTATE

func enter(previous_state_path: String, data: Dictionary = {}) -> void:
	var animation_current_state = animation_state_machine.get_current_node()
	if animation_current_state != "dive_action":
		animation_state_machine.travel("dive_action")
	player.velocity.y = player.DIVE_VERTICAL
	var new_model_forward = Vector3(sin(player_model.rotation.y), 0, cos(player_model.rotation.y)).normalized()
	player.velocity.x = new_model_forward.x * player.DIVE_HORIZONTAL
	player.velocity.z = new_model_forward.z * player.DIVE_HORIZONTAL
	current_dive_state = DIVESUBSTATE.INAIR
	dive_timer.start()

func physics_update(delta: float) -> void:
	if player.is_on_floor() and current_dive_state == DIVESUBSTATE.INAIR:
		current_dive_state = DIVESUBSTATE.ONFLOOR
	
	if current_dive_state == DIVESUBSTATE.INAIR or current_dive_state == DIVESUBSTATE.GETUP:
		var turn_speed_var = player.DIVE_TURN_SPEED if current_dive_state == DIVESUBSTATE.INAIR else player.TURNSPEED
		player.velocity += player.get_gravity() * delta * 1.7
		var user_input_dir_2d := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		var user_input_dir_3d := (player_camera.global_transform.basis * Vector3(user_input_dir_2d.x, 0, user_input_dir_2d.y)).normalized()
		var user_input_dir_3d_renormalized = Vector3(user_input_dir_3d.x, 0, user_input_dir_3d.z).normalized()
		
		var current_speed := Vector2(player.velocity.x, player.velocity.z).length()
		
		if user_input_dir_3d_renormalized:

			var input_angle := atan2(user_input_dir_3d_renormalized.x, user_input_dir_3d_renormalized.z)
			player_model.rotation.y = lerp_angle(player_model.rotation.y, input_angle, turn_speed_var)
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
	elif current_dive_state == DIVESUBSTATE.ONFLOOR:
		if (player.velocity.length() == 0):
			current_dive_state = DIVESUBSTATE.GETUP
			animation_state_machine.travel("dive_getup")
			await animation_tree.animation_finished
			var user_input_dir_2d := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
			if user_input_dir_2d:
				finished.emit(RUNNING)
			else:
				finished.emit(IDLE)
		var new_model_forward = Vector3(sin(player_model.rotation.y), 0, cos(player_model.rotation.y)).normalized()
		var user_input_dir_2d := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		var user_input_dir_3d := (player_camera.global_transform.basis * Vector3(user_input_dir_2d.x, 0, user_input_dir_2d.y)).normalized()
		
		var current_speed = Vector2(player.velocity.x, player.velocity.z).length()
		if user_input_dir_3d:
			var user_input_dir_3d_angle = atan2(user_input_dir_3d.x, user_input_dir_3d.z)
			player_model.rotation.y = lerp_angle(player_model.rotation.y, user_input_dir_3d_angle, player.DIVE_TURN_SPEED)
			player_model.rotation.y = wrapf(player_model.rotation.y, -PI, PI)
			
		current_speed = move_toward(current_speed, 0, player.DEACCEL * 0.5)
		player.velocity.x = new_model_forward.x * current_speed
		player.velocity.z = new_model_forward.z * current_speed

	player.move_and_slide()

func update(_delta:float):
	
	if Input.is_action_just_pressed("ui_accept") and current_dive_state == DIVESUBSTATE.ONFLOOR and isActionable:
		current_dive_state = DIVESUBSTATE.GETUP
		animation_state_machine.travel("dive_getup")
		await animation_tree.animation_finished
		var user_input_dir_2d := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		if user_input_dir_2d:
			finished.emit(RUNNING)
		else:
			finished.emit(IDLE)

func _on_dive_timer_timeout() -> void:
	print("dive timer timedout")
	isActionable = true
