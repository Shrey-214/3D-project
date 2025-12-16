#extends Area3D
#
## Where the player should appear when using this pad
#@export var target_position: Vector3
#
## For now we keep pads always on so it's easy to test.
#@export var start_active: bool = true
#
#var active: bool = false
#
#
#func _ready() -> void:
	## Start active or inactive based on the export flag.
	#active = start_active
#
	## Make sure the Area3D is actually detecting overlaps.
	#set_monitoring(active)
	#set_monitorable(true)
#
	## Connect overlap signal
	#area_entered.connect(_on_area_entered)
#
	## Optional: show/hide the pad visually if you want
	#_update_visual()
#
#
#func set_active(v: bool) -> void:
	#active = v
	#set_monitoring(v)
	#_update_visual()
#
#
#func _update_visual() -> void:
	## If you have a mesh as a child (e.g. cylinder), we can hide it when inactive.
	#var mesh := get_node_or_null("MeshInstance3D")
	#if mesh:
		#mesh.visible = active
#
#
#func _on_area_entered(area: Area3D) -> void:
	## Debug – you should see this in Output when the hand area touches the pad.
	#print("TeleportPad: area_entered from: ", area.name)
#
	#if not active:
		#print("TeleportPad is not active, ignoring.")
		#return
#
	## Only react to controller areas that are in group "hand"
	#if not area.is_in_group("hand"):
		#print("Area is not a 'hand', ignoring.")
		#return
#
	## Find the player (CharacterBody3D) from group "player"
	#var player := get_tree().get_first_node_in_group("player") as CharacterBody3D
	#if player == null:
		#print("No node in group 'player' found.")
		#return
#
	## Teleport the entire player rig to the desired position
	#var t := player.global_transform
	#t.origin = target_position
	#player.global_transform = t
#
	#print("Teleported player to: ", target_position)















extends Area3D

@export var target_position: Vector3
var active: bool = false

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	# make sure visuals match initial "active" value
	_update_visual()

func set_active(v: bool) -> void:
	active = v
	_update_visual()

func _update_visual() -> void:
	var mesh := get_node_or_null("MeshInstance3D")
	if mesh:
		mesh.visible = active  # only show when active

func _on_area_entered(area: Area3D) -> void:
	if not active:
		return
	if not area.is_in_group("hand"):
		return

	var player := get_tree().get_first_node_in_group("player") as CharacterBody3D
	if player:
		var t := player.global_transform
		t.origin = target_position
		player.global_transform = t

		# Call proper phase start depending on pad group
		if is_in_group("ore_to_animals"):
			player._start_level1_animals()
		elif is_in_group("animals_to_equip"):
			player._start_level1_equip()
		elif is_in_group("equip_to_level2"):
			player._start_level2_river()

		set_active(false)
