extends Area3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(setNpcZone)
	pass # Replace with function body.


func setNpcZone(body):
	if(body is npc):
		body.currentZone=self

