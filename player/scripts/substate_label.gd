extends Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#await owner.ready
	#state_machine = owner.get_node("StateMachine")
	if PlayerSignalBus:
		PlayerSignalBus.substate_changed.connect(_on_substate_changed)
		print("properly connected substate changed")

func _on_substate_changed(current:String) -> void:
	print("received the substate changed signal")
	set_text("Current Substate: " + current)
