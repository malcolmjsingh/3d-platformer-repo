extends Label

@onready var player: Player = $".."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if player.is_on_wall():
		text = "is on wall?: yes"
	else:
		text = "is on wall?: no"
