extends PlayerState

func enter(previous_state_path: String, data: Dictionary = {}) -> void:
	var animation_current_state = animation_state_machine.get_current_node()
	if not Input.is_action_pressed("crouch"):
		player.isCrouching = false
		PlayerSignalBus.substate_changed.emit("None")
		
	if player.isCrouching:
		if animation_current_state != "crouch_idle":
			animation_state_machine.travel("crouch_idle")
	else:
		if animation_current_state != "Ground":
			animation_state_machine.travel("Ground")
		animation_tree.set("parameters/Ground/blend_position", 0.0)
	

func update(_delta: float) -> void:
	var user_input_dir_2d := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if (user_input_dir_2d):
		finished.emit(RUNNING)
	
	if Input.is_action_just_pressed("ui_accept") and player.is_on_floor():
		finished.emit(JUMPING)
		
	if Input.is_action_pressed("crouch") and player.is_on_floor() and not player.isCrouching:
		PlayerSignalBus.substate_changed.emit("Crouch")
		player.isCrouching = true
		animation_state_machine.travel("to_crouch")

	if Input.is_action_just_released("crouch") and player.isCrouching:
		PlayerSignalBus.substate_changed.emit("None")
		player.isCrouching = false
		animation_state_machine.travel("from_crouch")
	
	if Input.is_action_just_pressed("secondary"):
		if (low_ray.is_colliding() and not high_ray.is_colliding()):
			print("attemping to grab")

func physics_update(_delta: float) -> void:
	if not player.is_on_floor():
		player.velocity += player.get_gravity() * _delta
		if (player.velocity.y < 0):
			finished.emit(FALLING)
	player.move_and_slide()

func exit():
	pass
