extends Area3D

@export var hits_to_break: int = 3
@export var hit_cooldown: float = 0.35  

var _hits: int = 0
var _can_hit: bool = true

func _ready() -> void:
	monitoring = true
	monitorable = true
	area_entered.connect(_on_area_entered)
	print("[Rock] READY hits_to_break=", hits_to_break)

func _on_area_entered(area: Area3D) -> void:
	if not _can_hit:
		return
	if area == null:
		return
	if not area.is_in_group("hand"):
		return

	# only left hand counts
	if area.name != "LeftHandArea":
		return

	_register_hit()

func _register_hit() -> void:
	_can_hit = false
	_hits += 1
	print("[Rock] HIT ", _hits, "/", hits_to_break)


	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("set_rock_hits"):
		player.call("set_rock_hits", _hits)


	if _hits >= hits_to_break:
		_break_rock()
		return


	get_tree().create_timer(hit_cooldown).timeout.connect(func():
		_can_hit = true
	)

func _break_rock() -> void:
	print("[Rock] BROKEN -> removing rock + ending game")


	var rock_root := get_parent()
	if rock_root:
		rock_root.queue_free()
	else:
		queue_free()


	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("on_rock_destroyed"):
		player.call("on_rock_destroyed")
