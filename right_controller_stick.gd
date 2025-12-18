extends XRController3D

@export var stick_length: float = 6.0
@export var collision_mask: int = 0xFFFFFFFF
@export var debug_print_hits: bool = true
@export var pickup_cooldown_time: float = 0.35

# drop settings (simple ground snap)
@export var drop_forward: float = 0.6
@export var drop_up: float = 0.2
@export var drop_down_ray: float = 5.0

@onready var stick_visual: MeshInstance3D = $StickVisual

var _enabled: bool = false
var _last_hit: Object = null
var _trigger_was_down: bool = false
var _pickup_cooldown: float = 0.0

var held_fruit_root: Node3D = null
var held_fruit_area: Area3D = null

const HOLD_OFFSET := Vector3(0, 0, -0.35)

func set_enabled(v: bool) -> void:
	_enabled = v
	if stick_visual:
		stick_visual.visible = v

func _ready() -> void:
	set_enabled(false)

func _physics_process(delta: float) -> void:
	if not _enabled or stick_visual == null:
		return

	if _pickup_cooldown > 0.0:
		_pickup_cooldown -= delta

	var origin: Vector3 = global_transform.origin
	var end: Vector3 = origin + (-global_transform.basis.z) * stick_length

	stick_visual.points[0] = origin
	stick_visual.points[1] = end

	var params := PhysicsRayQueryParameters3D.create(origin, end)
	params.collide_with_areas = true
	params.collide_with_bodies = true
	params.collision_mask = collision_mask

	var result: Dictionary = get_world_3d().direct_space_state.intersect_ray(params)

	var hit_fruit_area: Area3D = null

	if not result.is_empty():
		var hit_pos: Vector3 = result["position"]
		var collider = result["collider"]

		stick_visual.points[1] = hit_pos

		if debug_print_hits and collider != _last_hit and collider != null:
			_last_hit = collider
			if collider is Node:
				print("[Stick] hit: ", (collider as Node).name)
			else:
				print("[Stick] hit: ", collider)

		if collider is Area3D and (collider as Area3D).is_in_group("fruit"):
			hit_fruit_area = collider as Area3D
	else:
		_last_hit = null

	var trigger_down := get_float(&"trigger") > 0.8
	if trigger_down and not _trigger_was_down:
		_on_trigger_pressed(hit_fruit_area)
	_trigger_was_down = trigger_down


func _on_trigger_pressed(hit_fruit_area: Area3D) -> void:
	# holding -> try feed, else drop
	if held_fruit_root != null:
		if _pickup_cooldown > 0.0:
			print("[Stick] cooldown - can't feed/drop yet")
			return

		if _try_feed_if_touching_animal():
			return

		_drop_fruit_to_ground()
		return

	# not holding -> pick
	if hit_fruit_area == null:
		print("[Stick] trigger pressed but not aiming at fruit")
		return

	_pick_fruit_from_area(hit_fruit_area)


func _pick_fruit_from_area(fruit_area: Area3D) -> void:
	var root := fruit_area.get_parent() as Node3D
	if root == null:
		print("[Stick] fruit area has no Node3D parent")
		return

	held_fruit_root = root
	held_fruit_area = fruit_area

	root.reparent(self, true)
	root.transform.origin = HOLD_OFFSET

	held_fruit_area.monitoring = true
	held_fruit_area.monitorable = true

	_pickup_cooldown = pickup_cooldown_time
	print("[Stick] picked: ", root.name)


func _try_feed_if_touching_animal() -> bool:
	if held_fruit_area == null:
		return false

	var overlaps := held_fruit_area.get_overlapping_areas()
	if overlaps.is_empty():
		print("[Feed] not touching any Area3D")
		return false

	for a in overlaps:
		if a is Area3D and (a as Area3D).is_in_group("animal"):
			print("[Feed] FED -> banana disappears")

			if held_fruit_root:
				held_fruit_root.queue_free()

			held_fruit_root = null
			held_fruit_area = null

			var player := get_tree().get_first_node_in_group("player")
			if player and player.has_method("on_animal_fed"):
				player.call("on_animal_fed")

			return true

	print("[Feed] touching areas but none are in group 'animal'")
	return false


func _drop_fruit_to_ground() -> void:
	if held_fruit_root == null:
		return

	var world_root := get_tree().current_scene

	# compute a drop point in front of controller
	var forward := -global_transform.basis.z
	var start := global_transform.origin + forward * drop_forward + Vector3.UP * drop_up
	var down_end := start + Vector3.DOWN * drop_down_ray

	# move fruit back to scene first (keep global)
	held_fruit_root.reparent(world_root, true)

	# ray down to ground
	var params := PhysicsRayQueryParameters3D.create(start, down_end)
	params.collide_with_areas = false
	params.collide_with_bodies = true
	params.collision_mask = collision_mask

	var result := get_world_3d().direct_space_state.intersect_ray(params)
	if not result.is_empty():
		var ground_pos: Vector3 = result["position"]
		held_fruit_root.global_transform.origin = ground_pos + Vector3.UP * 0.05
		print("[Stick] dropped to ground at ", ground_pos)
	else:
		held_fruit_root.global_transform.origin = start
		print("[Stick] dropped (no ground hit)")

	held_fruit_root = null
	held_fruit_area = null
