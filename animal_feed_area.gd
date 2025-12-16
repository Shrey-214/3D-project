extends Area3D

var fed: bool = false

func _ready() -> void:
	add_to_group("animal_feed")
	monitoring = true
	monitorable = true
	area_entered.connect(_on_area_entered)
	print("[FeedArea] READY: ", name, " parent=", get_parent().name)

func _on_area_entered(area: Area3D) -> void:
	if fed:
		return

	# Only accept fruit areas (banana Area3D must be in group "fruit")
	if not area.is_in_group("fruit"):
		return

	print("[FeedArea] Fruit touched: ", area.name, " -> animal fed (banana will disappear)")

	# ✅ Banana disappears
	if area.has_method("consume"):
		area.call("consume")
	else:
		area.queue_free()

	# ✅ Animal stays, only mark fed once
	fed = true

	# Tell player to increment score / unlock teleport
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("on_animal_fed"):
		player.call("on_animal_fed")
