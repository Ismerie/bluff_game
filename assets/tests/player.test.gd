extends GutTest

var player_scene = preload("res://assets/prefab/Player.tscn")
var player


func before_each():
	player = player_scene.instantiate()
	add_child_autofree(player)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


# --- Gravité ---


func test_player_has_gravity_when_not_on_floor():
	player.velocity = Vector3.ZERO
	await wait_physics_frames(1)

	assert_lt(player.velocity.y, 0.0, "La gravité doit tirer le joueur vers le bas")


func test_player_velocity_is_zero_by_default():
	assert_eq(player.velocity, Vector3.ZERO, "La vélocité initiale doit être zéro")


# --- Rotation ---


func test_player_rotates_on_mouse_motion():
	var initial_rotation = player.rotation.y
	var mouse_motion_event = InputEventMouseMotion.new()
	mouse_motion_event.relative = Vector2(1, 1)
	player.handle_mouse_rotation(mouse_motion_event.relative.x)
	await wait_physics_frames(1)

	assert_ne(
		player.rotation.y,
		initial_rotation,
		"Le joueur doit tourner sur l'axe Y en fonction du mouvement de la souris"
	)


# --- Déplacement ---


func test_player_moves_forward_on_input():
	Input.action_press("move_forward")
	await wait_physics_frames(1)

	assert_gt(
		Vector2(player.velocity.x, player.velocity.z).length(),
		0.0,
		"Le joueur doit avoir une vitesse horizontale en avançant"
	)

	Input.action_release("move_forward")
	await wait_physics_frames(1)

	assert_eq(
		Vector2(player.velocity.x, player.velocity.z).length(),
		0.0,
		"Le joueur doit s'arrêter après avoir relâché la touche de déplacement"
	)


# --- Animations ---


func test_anim_tree_conditions():
	await wait_physics_frames(1)

	assert_false(
		player.anim_tree.get("parameters/conditions/is_walking"),
		"is_walking doit être false par défaut"
	)
	assert_true(
		player.anim_tree.get("parameters/conditions/is_not_walking"),
		"is_not_walking doit être true par défaut"
	)

	Input.action_press("move_forward")
	await wait_physics_frames(1)

	assert_true(
		player.anim_tree.get("parameters/conditions/is_walking"),
		"is_walking doit être true quand le joueur se déplace"
	)
	assert_false(
		player.anim_tree.get("parameters/conditions/is_not_walking"),
		"is_not_walking doit être false quand le joueur se déplace"
	)

	Input.action_release("move_forward")
	await wait_physics_frames(1)

	assert_false(
		player.anim_tree.get("parameters/conditions/is_walking"),
		"is_walking doit être false quand le joueur s'arrête"
	)
	assert_true(
		player.anim_tree.get("parameters/conditions/is_not_walking"),
		"is_not_walking doit être true quand le joueur s'arrête"
	)
