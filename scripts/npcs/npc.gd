extends StaticBody3D
class_name npc
@onready var geometryInstance=$Armature/Skeleton3D/Cylinder as GeometryInstance3D
@onready var navAgent= $NavigationAgent3D as NavigationAgent3D
@export var materials:Array[BaseMaterial3D]
@export var idleSounds:Array[Resource]
@export var speed:float
@export var idleTimerPeriod=3
var sphereRadius:float
@export var type: int
var idleTimer:float= 0
var currentZone: Area3D
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	currentZone=get_node("/root/root/Areas/1")
	sphereRadius= ((get_node("/root/root/Sphere") as MeshInstance3D)).scale.x
	navAgent.target_position=random_point_on_planet(currentZone.get_node("CollisionShape3D"))# would make sense to store the collision shape object instead of the area3d object will change lzm
	changeType(type)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	idleTimer-=delta
	if(idleTimer<0):
		$AnimationPlayer.play("RunAnim")
		if(navAgent.is_target_reached()):
			$AnimationPlayer.play("IdleAnim")
			if(randi()%10==0):
				(get_node(str(type)) as AudioStreamPlayer3D).play()
			idleTimer=idleTimerPeriod
			navAgent.target_position=random_point_on_planet(currentZone.get_node("CollisionShape3D"))
			return
		var next_path_position: Vector3 = navAgent.get_next_path_position()
		var newLocation: Vector3 = global_position.direction_to(next_path_position)*speed*delta
		var up :Vector3= global_position.normalized() 
		look_at(next_path_position,up)
		position+=newLocation


func radial_to_global(lat: float, lon: float) -> Vector3:
	return Vector3(
		sphereRadius * cos(lat) * sin(lon),
		sphereRadius * sin(lat),
		sphereRadius * cos(lat) * cos(lon)
	)
func random_point_on_planet(col: CollisionShape3D) -> Vector3:
	var cyl := col.shape as CylinderShape3D
	var a := randf() * TAU
	var r := cyl.radius * sqrt(randf())
	var p: Vector3 = col.global_transform * Vector3(cos(a) * r, 0, sin(a) * r)
	return p.normalized() * sphereRadius
func changeType(newType:int):
	type=newType
	geometryInstance.material_override=materials[newType]
func selectNpc(selected:bool):
	if(selected):
		$AnimationPlayer.play("SelectAnim")
		geometryInstance.set_instance_shader_parameter("outline_color",Color.WHITE)
	else:
		geometryInstance.set_instance_shader_parameter("outline_color",Color.BLACK)
