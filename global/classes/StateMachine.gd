class_name StateMachine extends Node

@export var initial_state: State = null

func get_initial_state() -> State:
	return initial_state if initial_state != null else get_child(0)

@onready var state: State = get_initial_state()

signal state_changed(previous_state_name:String, current_state_name: String)


func _ready() -> void:
	for state_node: State in find_children("*", "State"):
		state_node.finished.connect(_transition_to_next_state, CONNECT_DEFERRED)
		
	
	await owner.ready
	state_changed.emit("N/A",state.name)
	state.enter("")

func _transition_to_next_state(target_state_path: String, data := {}) -> void:
	print("conneted")
	if not has_node(target_state_path):
		printerr(owner.name + "tried to transition to state " + target_state_path + " but it does not exist.")
		return
	
	var previous_state_path := state.name
	state_changed.emit(state.name, target_state_path)
	state.exit()
	state = get_node(target_state_path)
	state.enter(previous_state_path, data)

func _unhandled_input(event: InputEvent) -> void:
	state.handle_input(event)

func _process(delta: float) -> void:
	state.update(delta)

func _physics_process(delta: float) -> void:
	state.physics_update(delta)
