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
