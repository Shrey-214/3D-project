extends Area3D

var fed: bool = false

func _ready() -> void:
	# IMPORTANT: controller script checks group "animal"
	add_to_group("animal")

	monitoring = true
	monitorable = true

	area_entered.connect(_on_area_entered)

	print("[FeedArea] READY:", name, " | parent=", get_parent().name, " | groups=", get_groups())


func _on_area_entered(area: Area3D) -> void:
	if fed:
		return

	# only accept fruit areas
	if area == null or not area.is_in_group("fruit"):
		return

	print("[FeedArea] Fruit touched:", area.name, " -> FEED!")

	# Fruit Area3D is child of BananaRoot, so delete the ROOT so mesh + collision disappear
	var fruit_root := area.get_parent()
	if fruit_root and fruit_root is Node:
		print("[FeedArea] Removing fruit root:", fruit_root.name)
		(fruit_root as Node).queue_free()
	else:
		print("[FeedArea] No fruit root, removing area only")
		area.queue_free()

	fed = true

	# notify player (increase count, enable teleport when done)
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("on_animal_fed"):
		player.call("on_animal_fed")
