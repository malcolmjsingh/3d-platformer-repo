extends Label

@onready var low_ray: RayCast3D = $"../LowRay"
@onready var high_ray: RayCast3D = $"../HighRay"

func _ready() -> void:
	pass # Replace with function body.



func _process(delta: float) -> void:
	
	if low_ray.is_colliding() and not high_ray.is_colliding():
		text = "is ledge?: yes"
	else:
		text = "is ledge?: no"
