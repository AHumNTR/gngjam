extends Node3D
@export var npcScene: PackedScene
@export var spawnAmount:int=15
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i  in range (spawnAmount):
		var npcInstance=npcScene.instantiate()

		add_child(npcInstance)
		npcInstance.position=Vector3(0,10,0)
		


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
