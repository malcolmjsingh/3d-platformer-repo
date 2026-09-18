extends Label

@export var state_machine: StateMachine

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#await owner.ready
	#state_machine = owner.get_node("StateMachine")
	if state_machine:
		state_machine.state_changed.connect(_on_state_changed)
		print("properly connected state changed")

func _on_state_changed(prev:String, current:String) -> void:
	print("received the state changed signal")
	set_text("Prev: " + prev + " Current: " + current)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
