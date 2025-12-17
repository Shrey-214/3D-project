#extends CharacterBody3D
#
#enum GamePhase { LEVEL0_ORE, LEVEL1_ANIMALS, LEVEL1_EQUIP, LEVEL2_RIVER, COMPLETE }
#var phase: GamePhase = GamePhase.LEVEL0_ORE
#
## ---- COUNTERS ----
#var ore_count: int = 0
#const ORE_TARGET := 5
#
#var animals_fed: int = 0
#var total_animals: int = 0
#
#var equipment_count: int = 0
#const EQUIP_TARGET := 5
#
## Lights
#@onready var dir_light: DirectionalLight3D = $"../DirectionalLight3D"
#
#const MOVE_SPEED      := 5.0
#const INPUT_DEADZONE  := 0.2
#const SNAP_ANGLE_DEG  := 30.0
#const SNAP_COOLDOWN   := 0.25
#
#@onready var xr_origin: XROrigin3D            = $XROrigin3D
#@onready var head: XRCamera3D                 = $XROrigin3D/XRCamera3D
#@onready var left_controller: XRController3D  = $XROrigin3D/LeftController
#@onready var right_controller: XRController3D = $XROrigin3D/RightController
#
#@onready var flashlight: Node3D = $XROrigin3D/RightController/Flashlight
#
#@onready var left_hand_area: Area3D  = $XROrigin3D/LeftController/LeftHandArea
#@onready var right_hand_area: Area3D = $XROrigin3D/RightController/RightHandArea
#
#@onready var left_hand_shape: CollisionShape3D  = left_hand_area.get_node("CollisionShape3D")
#@onready var right_hand_shape: CollisionShape3D = right_hand_area.get_node("CollisionShape3D")
#
## Right controller script has set_enabled(bool)
#@onready var right_stick_controller: Node = $XROrigin3D/RightController
#
#var _turn_cooldown: float = 0.0
#
#func _ready() -> void:
	#add_to_group("player")
	#_start_level0()
#
#func _physics_process(delta: float) -> void:
	#var move_input := _get_move_input()
#
	#if move_input.length() > INPUT_DEADZONE:
		#_move_player(move_input)
	#else:
		#velocity.x = 0.0
		#velocity.z = 0.0
#
	#velocity.y = 0.0
	#move_and_slide()
#
	#if _turn_cooldown > 0.0:
		#_turn_cooldown -= delta
	#else:
		#_handle_snap_turn()
#
## ------------ Movement ------------
#func _get_move_input() -> Vector2:
	#var input_vec := Vector2.ZERO
#
	## Keyboard fallback
	#input_vec.x += Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	#input_vec.y += Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
#
	## Left controller stick
	#if is_instance_valid(left_controller):
		#var left_stick: Vector2 = left_controller.get_vector2(&"primary")
		#input_vec += left_stick
#
	## fallback to right stick Y if needed
	#if input_vec.length() < 0.05 and is_instance_valid(right_controller):
		#var right_stick: Vector2 = right_controller.get_vector2(&"primary")
		#input_vec.y += right_stick.y
#
	#return input_vec
#
#func _move_player(input_vec: Vector2) -> void:
	#var forward: Vector3 = -head.global_transform.basis.z
	#forward.y = 0.0
	#forward = forward.normalized()
#
	#var right: Vector3 = head.global_transform.basis.x
	#right.y = 0.0
	#right = right.normalized()
#
	#var dir: Vector3 = forward * input_vec.y + right * input_vec.x
	#if dir.length() > 0.0:
		#dir = dir.normalized()
#
	#var vel := dir * MOVE_SPEED
	#velocity.x = vel.x
	#velocity.z = vel.z
#
## ------------ Snap turning ------------
#func _handle_snap_turn() -> void:
	#if not is_instance_valid(right_controller):
		#return
#
	#var stick: Vector2 = right_controller.get_vector2(&"primary")
	#var threshold := 0.7
#
	#if stick.x > threshold:
		#xr_origin.rotate_y(-deg_to_rad(SNAP_ANGLE_DEG))
		#_turn_cooldown = SNAP_COOLDOWN
	#elif stick.x < -threshold:
		#xr_origin.rotate_y(deg_to_rad(SNAP_ANGLE_DEG))
		#_turn_cooldown = SNAP_COOLDOWN
#
## ------------ Phase helpers ------------
#func _set_dark_jungle(on: bool) -> void:
	#if not dir_light:
		#return
	#dir_light.light_energy = 0.15 if on else 1.0
#
#func _set_bubble_cursor_enabled(enabled: bool) -> void:
	## You can keep this, but you said you're not using bubble cursor now
	#var big_radius := 0.4
	#var small_radius := 0.12
	#var r := big_radius if enabled else small_radius
#
	#if left_hand_shape and left_hand_shape.shape is SphereShape3D:
		#(left_hand_shape.shape as SphereShape3D).radius = r
	#if right_hand_shape and right_hand_shape.shape is SphereShape3D:
		#(right_hand_shape.shape as SphereShape3D).radius = r
#
#func _set_stick_enabled(enabled: bool) -> void:
	#if right_stick_controller and right_stick_controller.has_method("set_enabled"):
		#right_stick_controller.call("set_enabled", enabled)
#
#func _activate_teleport_group(group_name: String) -> void:
	#var pads := get_tree().get_nodes_in_group(group_name)
	#for p in pads:
		#if p.has_method("set_active"):
			#p.set_active(true)
#
## ------------ Level starts ------------
#func _start_level0() -> void:
	#phase = GamePhase.LEVEL0_ORE
	#ore_count = 0
	#animals_fed = 0
	#equipment_count = 0
#
	#_set_dark_jungle(true)
	#_set_bubble_cursor_enabled(false)
#
	#_set_stick_enabled(false) # stick OFF in level 0
	#if flashlight:
		#flashlight.visible = false
#
#func _start_level1_animals() -> void:
	#phase = GamePhase.LEVEL1_ANIMALS
	#_set_dark_jungle(false)
	#_set_bubble_cursor_enabled(false)
#
	#_set_stick_enabled(true) # stick ON only in level 1
	#if flashlight:
		#flashlight.visible = false
#
	#total_animals = get_tree().get_nodes_in_group("animal").size()
	#animals_fed = 0
	#print("LEVEL 1: Feed all animals (stick enabled)")
#
#func _start_level1_equip() -> void:
	#phase = GamePhase.LEVEL1_EQUIP
	#_set_dark_jungle(true)
	#_set_bubble_cursor_enabled(false)
#
	#_set_stick_enabled(false)
	#if flashlight:
		#flashlight.visible = true
#
	#equipment_count = 0
	#print("LEVEL 1 EQUIP: find 5 tools")
#
#func _start_level2_river() -> void:
	#phase = GamePhase.LEVEL2_RIVER
	#_set_dark_jungle(false)
	#_set_bubble_cursor_enabled(false)
#
	#_set_stick_enabled(false)
	#if flashlight:
		#flashlight.visible = false
#
	#print("LEVEL 2: Clear the stone from the river")
#
## ------------ Game events ------------
#func add_ore(amount: int = 1) -> void:
	#if phase != GamePhase.LEVEL0_ORE:
		#return
	#ore_count += amount
	#print("Ore:", ore_count, "/", ORE_TARGET)
	#if ore_count >= ORE_TARGET:
		#_activate_teleport_group("ore_to_animals")
#
#func on_animal_fed() -> void:
	#if phase != GamePhase.LEVEL1_ANIMALS:
		#return
	#animals_fed += 1
	#print("Animals fed:", animals_fed, "/", total_animals)
	#if animals_fed >= total_animals:
		#_activate_teleport_group("animals_to_equip")
#
#func add_equipment(amount: int = 1) -> void:
	#if phase != GamePhase.LEVEL1_EQUIP:
		#return
	#equipment_count += amount
	#print("Equipment:", equipment_count, "/", EQUIP_TARGET)
	#if equipment_count >= EQUIP_TARGET:
		#_activate_teleport_group("equip_to_level2")
#
#func notify_stone_cleared() -> void:
	#if phase != GamePhase.LEVEL2_RIVER:
		#return
	#phase = GamePhase.COMPLETE
	#print("GAME COMPLETE! The river flows again.")
#
#func is_in_animals_phase() -> bool:
	#return phase == GamePhase.LEVEL1_ANIMALS

extends CharacterBody3D

enum GamePhase { LEVEL0_ORE, LEVEL1_ANIMALS, LEVEL1_EQUIP, LEVEL2_RIVER, COMPLETE }
var phase: GamePhase = GamePhase.LEVEL0_ORE

var ore_count: int = 0
const ORE_TARGET := 5

var animals_fed: int = 0
var total_animals: int = 0

var equipment_count: int = 0
const EQUIP_TARGET := 4

@onready var dir_light: DirectionalLight3D = $"../DirectionalLight3D"

@onready var xr_origin: XROrigin3D = $XROrigin3D
@onready var head: XRCamera3D = $XROrigin3D/XRCamera3D
@onready var left_controller: XRController3D = $XROrigin3D/LeftController
@onready var right_controller: XRController3D = $XROrigin3D/RightController

@onready var flashlight: Node3D = $XROrigin3D/RightController/Flashlight

@onready var rapid_tp = $RapidTeleport  # if you attach script to a child node

const MOVE_SPEED := 5.0
const INPUT_DEADZONE := 0.2
const SNAP_ANGLE_DEG := 30.0
const SNAP_COOLDOWN := 0.25

var _turn_cooldown: float = 0.0

func _ready() -> void:
	_start_level0()
	_activate_teleport_group("equip_to_level2")

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
	_set_dark_jungle(true)
	

	_enable_stick(false)
	_enable_rapid_teleport(false)

	if flashlight:
		flashlight.visible = false

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

func _start_level1_equip() -> void:
	phase = GamePhase.LEVEL1_EQUIP
	_set_dark_jungle(true)

	_enable_stick(false)
	
	_enable_rapid_teleport(false)

	if flashlight:
		flashlight.visible = true

	equipment_count = 0
	print("LEVEL 1 EQUIP: Find 5 tools")

func _start_level2_river() -> void:
	phase = GamePhase.LEVEL2_RIVER
	_set_dark_jungle(false)

	_enable_stick(false)
	
	_enable_rapid_teleport(true)

	if flashlight:
		flashlight.visible = false

	print("LEVEL 2: Clear the stone from the river")

func _enable_stick(on: bool) -> void:
	if right_controller and right_controller.has_method("set_enabled"):
		right_controller.call("set_enabled", on)

func _set_dark_jungle(on: bool) -> void:
	if not dir_light:
		return
	dir_light.light_energy = 0.15 if on else 1.0

# ---------------- Progress counters ----------------

func add_ore(amount: int = 1) -> void:
	if phase != GamePhase.LEVEL0_ORE:
		return
	ore_count += amount
	print("Ore:", ore_count, "/", ORE_TARGET)
	if ore_count >= ORE_TARGET:
		_activate_teleport_group("ore_to_animals")

func on_animal_fed() -> void:
	if phase != GamePhase.LEVEL1_ANIMALS:
		return

	animals_fed += 1
	print("Animals fed:", animals_fed, "/", total_animals)

	if animals_fed >= total_animals:
		_activate_teleport_group("animals_to_equip")

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

func on_rock_destroyed() -> void:
	if phase != GamePhase.LEVEL2_RIVER:
		return

	phase = GamePhase.COMPLETE
	print("GAME OVER: Rock destroyed ✅")

	_enable_stick(false)
	_enable_rapid_teleport(false)

	if flashlight:
		flashlight.visible = false

func add_equipment(amount: int = 1) -> void:
	if phase != GamePhase.LEVEL1_EQUIP:
		return

	equipment_count += amount
	print("Equipment:", equipment_count, "/", EQUIP_TARGET)

	if equipment_count >= EQUIP_TARGET:
		_activate_teleport_group("equip_to_level2")
