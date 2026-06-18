extends GutTest

var player_scene = preload("res://assets/prefab/Player.tscn")
var player


func before_each():
	player = player_scene.instantiate()
	add_child_autofree(player)


func test_player_has_gravity_when_not_on_floor():
	player.velocity = Vector3.ZERO

	await wait_physics_frames(1)

	assert_lt(player.velocity.y, 0.0, "La gravité doit tirer le joueur vers le bas")


func test_player_velocity_is_zero_by_default():
	assert_eq(player.velocity, Vector3.ZERO, "La vélocité initiale doit être zéro")
