extends CharacterBody3D

enum GamePhase { LEVEL0_ORE, LEVEL1_ANIMALS, LEVEL1_EQUIP, LEVEL2_RIVER, COMPLETE }
var phase: GamePhase = GamePhase.LEVEL0_ORE

var ore_count: int = 0
const ORE_TARGET := 5

var animals_fed: int = 0
var total_animals: int = 0

var equipment_count: int = 0
const EQUIP_TARGET := 4

# rock hit counter (Level 2 / Rock level)
var rock_hits: int = 0
const ROCK_HIT_TARGET := 3

@onready var dir_light: DirectionalLight3D = $"../DirectionalLight3D"

@onready var xr_origin: XROrigin3D = $XROrigin3D
@onready var head: XRCamera3D = $XROrigin3D/XRCamera3D
@onready var left_controller: XRController3D = $XROrigin3D/LeftController
@onready var right_controller: XRController3D = $XROrigin3D/RightController

@onready var flashlight: Node3D = $XROrigin3D/RightController/Flashlight
@onready var rapid_tp = $RapidTeleport

# HUD label path 
@onready var hud_label: Label = $XROrigin3D/XRCamera3D/HUDViewport/UIRoot/TopLeftLabel

const MOVE_SPEED := 5.0
const INPUT_DEADZONE := 0.2
const SNAP_ANGLE_DEG := 30.0
const SNAP_COOLDOWN := 0.25

var _turn_cooldown: float = 0.0

func _ready() -> void:
	_start_level0()
	#_activate_teleport_group("equip_to_level2")
	_update_hud()

func _physics_process(delta: float) -> void:
	var move_input := _get_move_input()

	if move_input.length() > INPUT_DEADZONE:
		_move_player(move_input)
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	velocity.y = 0.0
	move_and_slide()

	if _turn_cooldown > 0.0:
		_turn_cooldown -= delta
	else:
		_handle_snap_turn()

func _get_move_input() -> Vector2:
	var input_vec := Vector2.ZERO
	input_vec.x += Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vec.y += Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")

	if is_instance_valid(left_controller):
		input_vec += left_controller.get_vector2(&"primary")

	if input_vec.length() < 0.05 and is_instance_valid(right_controller):
		input_vec.y += right_controller.get_vector2(&"primary").y

	return input_vec

func _move_player(input_vec: Vector2) -> void:
	var forward := -head.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()

	var right := head.global_transform.basis.x
	right.y = 0.0
	right = right.normalized()

	var dir := (forward * input_vec.y + right * input_vec.x).normalized()
	var vel := dir * MOVE_SPEED
	velocity.x = vel.x
	velocity.z = vel.z

func _handle_snap_turn() -> void:
	if not is_instance_valid(right_controller):
		return

	var stick := right_controller.get_vector2(&"primary")
	var threshold := 0.7

	if stick.x > threshold:
		xr_origin.rotate_y(-deg_to_rad(SNAP_ANGLE_DEG))
		_turn_cooldown = SNAP_COOLDOWN
	elif stick.x < -threshold:
		xr_origin.rotate_y(deg_to_rad(SNAP_ANGLE_DEG))
		_turn_cooldown = SNAP_COOLDOWN

# ---------------- Levels ----------------

func _start_level0() -> void:
	phase = GamePhase.LEVEL0_ORE
	ore_count = 0
	animals_fed = 0
	equipment_count = 0
	rock_hits = 0

	_set_dark_jungle(true)

	_enable_stick(false)
	_enable_rapid_teleport(false)

	if flashlight:
		flashlight.visible = false

	_update_hud()

func _start_level1_animals() -> void:
	phase = GamePhase.LEVEL1_ANIMALS
	_set_dark_jungle(false)

	total_animals = get_tree().get_nodes_in_group("animal").size()
	animals_fed = 0

	_enable_stick(true)
	_enable_rapid_teleport(false)

	if flashlight:
		flashlight.visible = false

	print("LEVEL 1: Feed all animals (stick enabled)")
	_update_hud()

func _start_level1_equip() -> void:
	phase = GamePhase.LEVEL1_EQUIP
	_set_dark_jungle(true)

	_enable_stick(false)
	_enable_rapid_teleport(false)

	if flashlight:
		flashlight.visible = true

	equipment_count = 0
	print("LEVEL 1 EQUIP: Find 4 items")
	_update_hud()

func _start_level2_river() -> void:
	phase = GamePhase.LEVEL2_RIVER
	_set_dark_jungle(false)

	_enable_stick(false)
	_enable_rapid_teleport(true)

	if flashlight:
		flashlight.visible = false

	rock_hits = 0
	print("LEVEL 2: Clear the stone from the river")
	_update_hud()

func _enable_stick(on: bool) -> void:
	if right_controller and right_controller.has_method("set_enabled"):
		right_controller.call("set_enabled", on)

func _set_dark_jungle(on: bool) -> void:
	if dir_light:
		dir_light.light_energy = 0.03 if on else 1.2

	var we := get_node_or_null("../WorldEnvironment") as WorldEnvironment
	if we and we.environment:
		we.environment.ambient_light_energy = 0.05 if on else 1.0

# ---------------- Progress counters ----------------

func add_ore(amount: int = 1) -> void:
	if phase != GamePhase.LEVEL0_ORE:
		return
	ore_count += amount
	print("Ore:", ore_count, "/", ORE_TARGET)

	_update_hud()

	if ore_count >= ORE_TARGET:
		_activate_teleport_group("ore_to_animals")

func on_animal_fed() -> void:
	if phase != GamePhase.LEVEL1_ANIMALS:
		return

	animals_fed += 1
	print("Animals fed:", animals_fed, "/", total_animals)

	_update_hud()

	if animals_fed >= total_animals:
		_activate_teleport_group("animals_to_equip")

func add_equipment(amount: int = 1) -> void:
	if phase != GamePhase.LEVEL1_EQUIP:
		return

	equipment_count += amount
	print("Equipment:", equipment_count, "/", EQUIP_TARGET)

	_update_hud()

	if equipment_count >= EQUIP_TARGET:
		_activate_teleport_group("equip_to_level2")

func set_rock_hits(hits: int) -> void:
	rock_hits = hits
	_update_hud()

func on_rock_destroyed() -> void:
	if phase != GamePhase.LEVEL2_RIVER:
		return

	phase = GamePhase.COMPLETE
	print("GAME OVER: Rock destroyed")

	_enable_stick(false)
	_enable_rapid_teleport(false)

	if flashlight:
		flashlight.visible = false

	_update_hud()

func _activate_teleport_group(group_name: String) -> void:
	var pads := get_tree().get_nodes_in_group(group_name)
	for p in pads:
		if p.has_method("set_active"):
			p.set_active(true)

func is_in_animals_phase() -> bool:
	return phase == GamePhase.LEVEL1_ANIMALS

func _enable_rapid_teleport(on: bool) -> void:
	if xr_origin and xr_origin.has_method("set_enabled"):
		xr_origin.call("set_enabled", on)

# ---------------- HUD ----------------

func _update_hud() -> void:
	if hud_label == null:
		return

	var title := ""
	var line1 := ""
	var line2 := ""

	match phase:
		GamePhase.LEVEL0_ORE:
			
			line1 = "Ores: %d/%d" % [ore_count, ORE_TARGET]
			

		GamePhase.LEVEL1_ANIMALS:
		
			line1 = "Fed: %d/%d" % [animals_fed, total_animals]
			

		GamePhase.LEVEL1_EQUIP:
		
			line1 = "Items: %d/%d" % [equipment_count, EQUIP_TARGET]
			

		GamePhase.LEVEL2_RIVER:
			
			line1 = "Hits: %d/%d" % [rock_hits, ROCK_HIT_TARGET]
		

		GamePhase.COMPLETE:
			line1 = "GAME OVER"
			

	hud_label.text = "%s\n%s\n%s" % [title, line1, line2]
