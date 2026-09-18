extends PlayerState
@onready var spin_timer: Timer = $SpinTimer
var spin_lift = 3.0
var spin_add = 1.0
var gravity_modifier = 0.8

func enter(_previous_state_path: String, _data: Dictionary = {}) -> void:
	var animation_current_state = animation_state_machine.get_current_node()
	if player.isCrouching:
		if animation_current_state != "crouch_idle":
			animation_state_machine.travel("crouch_idle")
	else:
		if animation_current_state != "Fall":
			animation_state_machine.travel("Fall")
	spin_timer.start()
	if player.velocity.y <= 0:
		player.velocity.y += spin_lift
	elif player.velocity.y > 0:
		player.velocity.y += spin_add

func exit():
	pass

func update(_delta: float) -> void:
	if Input.is_action_just_released("crouch") and player.isCrouching:
		PlayerSignalBus.substate_changed.emit("None")
		player.isCrouching = false
		animation_state_machine.travel("Fall")


func physics_update(_delta: float) -> void:
	if not player.is_on_floor():
		player.velocity += player.get_gravity() * _delta * gravity_modifier

	var user_input_dir_2d := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var user_input_dir_3d := (player_camera.global_transform.basis * Vector3(user_input_dir_2d.x, 0, user_input_dir_2d.y)).normalized()
	
	var current_speed = Vector2(player.velocity.x, player.velocity.z).length()
	if user_input_dir_3d:
		var user_input_dir_3d_angle = atan2(user_input_dir_3d.x, user_input_dir_3d.z)
		player_model.rotation.y = lerp_angle(player_model.rotation.y, user_input_dir_3d_angle, player.TURNSPEED)
		player_model.rotation.y = wrapf(player_model.rotation.y, -PI, PI)
		
		current_speed = move_toward(current_speed, player.CURRENT_MAX_SPEED, player.ACCEL)
	else:
		current_speed = move_toward(current_speed, 0, player.DEACCEL)
	
	var new_model_forward = Vector3(sin(player_model.rotation.y), 0, cos(player_model.rotation.y)).normalized()
	
	player.velocity.x = new_model_forward.x * current_speed
	player.velocity.z = new_model_forward.z * current_speed
	player.move_and_slide()


func _on_spin_timer_timeout() -> void:
	if not player.is_on_floor():
		finished.emit(FALLING)
	elif player.is_on_floor():
		if (player.velocity.length() == 0):
			finished.emit(IDLE)
		else:
			finished.emit(RUNNING)
