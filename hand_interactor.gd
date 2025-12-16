extends Area3D

var _hovered_ore: Area3D = null

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _on_area_entered(area: Area3D) -> void:
	if area.is_in_group("ore"):
		_hovered_ore = area

func _on_area_exited(area: Area3D) -> void:
	if area == _hovered_ore:
		_hovered_ore = null

func _process(delta: float) -> void:
	if _hovered_ore == null:
		return

	# Get trigger value from the parent XRController3D
	var controller := get_parent() as XRController3D
	if controller == null:
		return

	var trigger_value := controller.get_float(&"trigger")  # 0.0 .. 1.0
	if trigger_value > 0.8:
		if is_instance_valid(_hovered_ore) and _hovered_ore.has_method("collect"):
			_hovered_ore.collect()
			_hovered_ore = null   # so we don't double-collect
