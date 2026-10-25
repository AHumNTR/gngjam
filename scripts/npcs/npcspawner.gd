extends Node3D
@export var npcScene: PackedScene
@export var spawnAmount:Array[int]=[1,1,1,2]
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i  in range (4):
		for j  in range (spawnAmount[i]):
			var npcInstance=npcScene.instantiate()
			add_child(npcInstance)
			npcInstance.position=Vector3(0,10,0)
			npcInstance.changeType(i)
		


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
