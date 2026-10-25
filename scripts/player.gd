extends Node3D

@export var mouse_sensitivity: float = 0.003
@export var distance := 10.0
@export var rotate_speed := 0.005
@export var npcScene: PackedScene

var yaw := 0.0
var pitch := 0.3
var npcs: Array[npc] 
var areas: Array[Area3D] 
var sphereRadius
var roundCount:=0
var handMode:=0
var actionRemaining:= [0,9999,9999]
@export var typeValues:Array[type_values]
@export var cursorImages:Array[Resource]
enum actionNames{
kill,
move,
switch
}
@export var commanderTextures :Array[Texture2D]
var commanderRect:TextureRect
func _ready() -> void:

	commanderRect=get_node("/root/root/Control/Commander")
	sphereRadius= ((get_node("/root/root/Sphere") as MeshInstance3D)).scale.x
	for c in get_node("/root/root/npcs").get_children():
		if c is npc:
			npcs.append(c)

	for c in get_node("/root/root/Areas").get_children():
		if c is Area3D:
			areas.append(c)
	_update_camera()


var targetNpc:npc=null
func _unhandled_input(event: InputEvent) -> void:

	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		yaw -= event.relative.x * rotate_speed
		pitch = clamp(pitch + event.relative.y * rotate_speed, -1.5, 1.5)
		_update_camera()

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if(handMode==0 and actionRemaining[0]>0):
			var cam := get_viewport().get_camera_3d()
			var space_state = get_world_3d().direct_space_state
			var from := cam.project_ray_origin(event.position)
			var to := from + cam.project_ray_normal(event.position) * 1000.0
			var query = PhysicsRayQueryParameters3D.create(from, to)
			query.collide_with_areas = true
			var result = space_state.intersect_ray(query)
			if(result.get("collider") is npc):
				var npcToTest= ( result.get("collider")as npc )
				if(npcToTest.type!=roundCount%3):
					npcToTest.queue_free()
					refreshNpcList()
					actionRemaining[0]-=1
		elif(handMode==1 ):
			if(targetNpc!=null and actionRemaining[1]>0):
				var cam := get_viewport().get_camera_3d()
				var space_state = get_world_3d().direct_space_state
				var from := cam.project_ray_origin(event.position)
				var to := from + cam.project_ray_normal(event.position) * 1000.0

				var query = PhysicsRayQueryParameters3D.create(from, to)
				query.collide_with_areas = true
				var result = space_state.intersect_ray(query)
				if(result.get("collider") is Area3D):
					var areaObject:=result.get("collider") as Area3D
					if(areaObject!=targetNpc.currentZone):
						targetNpc.navAgent.target_position=	random_point_on_planet((areaObject.get_node("CollisionShape3D") as CollisionShape3D))
						actionRemaining[1]-=1
						targetNpc.idleTimer=0
				elif(result.get("collider") is npc):
					targetNpc.selectNpc(false)
					targetNpc=result.get("collider") as npc
					targetNpc.selectNpc(true)

				
			else:
				var cam := get_viewport().get_camera_3d()
				var space_state = get_world_3d().direct_space_state
				var from := cam.project_ray_origin(event.position)
				var to := from + cam.project_ray_normal(event.position) * 1000.0
				var query = PhysicsRayQueryParameters3D.create(from, to)
				query.collide_with_areas = true
				var result = space_state.intersect_ray(query)
				if(result.get("collider") is npc):
					if(targetNpc!=null):
						targetNpc.selectNpc(false)
					targetNpc=result.get("collider") as npc
					targetNpc.selectNpc(true)
					
		elif(handMode==2 and actionRemaining[2]>0):
			var cam := get_viewport().get_camera_3d()
			var space_state = get_world_3d().direct_space_state
			var from := cam.project_ray_origin(event.position)
			var to := from + cam.project_ray_normal(event.position) * 1000.0
			var query = PhysicsRayQueryParameters3D.create(from, to)
			query.collide_with_areas = true
			var result = space_state.intersect_ray(query)
			if(result.get("collider") is npc):

				var npcToCheck=( result.get("collider")as npc )		
				if(npcToCheck.type!=roundCount%3):
					npcToCheck.changeType(roundCount%3)
					actionRemaining[2]-=1




var dominantCountsLastRound=[0,0,0,0]
var fullyDominantCountsLastRound=[0,0,0,0]
func _update_camera() -> void:
	global_position = Vector3(cos(pitch) * sin(yaw), sin(pitch), cos(pitch) * cos(yaw)) * distance
	look_at(Vector3.ZERO)
func _on_next_pressed() -> void:
	for area in areas:
		var count= [0,0,0,0]	
		var totalCount=0
		var npcsInArea=area.get_overlapping_bodies()

		for npcObj in 	npcsInArea:
			if(npcObj is npc):
				count[npcObj.type]+=1
				totalCount+=1
		var npcsNode=get_node("/root/root/npcs")
		for i in range(3):
			if(count[i]!=0):
				for j in range(typeValues[i].spawnRate):
					var spawnedNpc= npcScene.instantiate()
					spawnedNpc.currentZone=area
					npcsNode.add_child(spawnedNpc)
					spawnedNpc.position= random_point_on_planet(area.get_node("CollisionShape3D"))
					spawnedNpc.navAgent.target_position=random_point_on_planet(area.get_node("CollisionShape3D"))
					spawnedNpc.changeType(i)
					


		var mostDominant=count.find(count.max())

		if(count[mostDominant]>totalCount/2.0):
			if(count[mostDominant]==totalCount):
				fullyDominantCountsLastRound[mostDominant]+=1
			dominantCountsLastRound[mostDominant]+=1
			var dominantTypeValues:=typeValues[mostDominant] 
			var needToSwitchCount=min(dominantTypeValues.switchRate,totalCount-count[mostDominant])#either do the max eligible people we got or the class limit
			var switchedCount=0
			var idToTarget=(mostDominant+1)%3
			for targetNpc in npcsInArea:
				if(needToSwitchCount>switchedCount):
					if(targetNpc is npc and targetNpc.type==idToTarget):
						switchedCount+=1
						count[idToTarget]-=1
						count[mostDominant]+=1
						targetNpc.changeType(mostDominant)
			#after doing a one pass on the primary enemy target the secondary enemy

			idToTarget=(mostDominant+2)%3
			for targetNpc in npcsInArea:
				if(needToSwitchCount>switchedCount):
					if(targetNpc is npc and targetNpc.type==idToTarget):
						switchedCount+=1
						count[idToTarget]-=1
						count[mostDominant]+=1
						targetNpc.changeType(mostDominant)
			var needToKillCount=min(dominantTypeValues.killRate,totalCount-count[mostDominant])#either do the max eligible people we got or the class limit
			idToTarget=(mostDominant+1)%3
			var killedCount=0
			for targetNpc in npcsInArea:
				if(needToKillCount>killedCount):
					if(targetNpc is npc and targetNpc.type==idToTarget):
						killedCount+=1
						count[idToTarget]-=1
						targetNpc.queue_free()

			idToTarget=(mostDominant+2)%3

			for targetNpc in npcsInArea:
				if(needToKillCount>killedCount):
					if(targetNpc is npc and targetNpc.type==idToTarget):
						killedCount+=1
						count[idToTarget]-=1
						targetNpc.queue_free()
			refreshNpcList()
	actionRemaining=[1,1,1]
	roundCount+=1
	if(roundCount==9):
		finish_game()
	
	if(targetNpc!=null):
		targetNpc.selectNpc(false)
	targetNpc=null
	commanderRect.texture=commanderTextures[roundCount%3]
	if(handMode>=2):
		Input.set_custom_mouse_cursor(cursorImages[2+(roundCount%3)],0,Vector2(10,52))
			
			
func refreshNpcList():
	npcs.clear()
	for c in get_node("/root/root/npcs").get_children():
		if c is npc:
			npcs.append(c)


func _on_mode_button_pressed(newMode: int) -> void:
	handMode=newMode

	if(newMode==0):
		Input.set_custom_mouse_cursor(cursorImages[newMode],0,Vector2(60,115))
	elif(newMode==1):
		Input.set_custom_mouse_cursor(cursorImages[newMode],0,Vector2(65,104))
	else:
		Input.set_custom_mouse_cursor(cursorImages[2+(roundCount%3)],0,Vector2(10,52))	

func random_point_on_planet(col: CollisionShape3D) -> Vector3:#also on npc class should fix
	var cyl := col.shape as CylinderShape3D
	var a := randf() * TAU
	var r := cyl.radius * sqrt(randf())
	var p: Vector3 = col.global_transform * Vector3(cos(a) * r, 0, sin(a) * r)
	return p.normalized() * sphereRadius
func finish_game():
	var totalYellowCount:int=0
	var redDominationCount:int=dominantCountsLastRound[2]
	var blueFullyDominated:int=fullyDominantCountsLastRound[1]
	refreshNpcList()
	print("finished")
	for x in npcs:
		if(x.type==0):
			totalYellowCount+=1
	if(float(totalYellowCount)/npcs.size()>=0.8):
		print("Yellow won")
	if(redDominationCount>=3):
		print("Red Won")
	if(blueFullyDominated>2):
		print("Blue Won")
	
