extends CharacterBody3D

const MOVEMENT_SPEED: float = 5.0

@export var mouse_sensibility: float
@export var camera: Camera3D

var camera_rotation_x: float

@onready var anim_tree = $AnimationTree


func _init() -> void:
	camera_rotation_x = 0.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseMotion:
		handle_mouse_rotation(event.relative)


func handle_mouse_rotation(relative: Vector2) -> void:
	rotate_y(-relative.x * mouse_sensibility)
	camera_rotation_x -= relative.y * mouse_sensibility
	camera_rotation_x = clamp(camera_rotation_x, deg_to_rad(-90), deg_to_rad(90))
	camera.rotation.x = camera_rotation_x


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (
		(transform.basis.x * -input_dir.x + transform.basis.z * -input_dir.y).normalized()
	)
	var is_walking = direction.length() > 0

	velocity.x = direction.x * MOVEMENT_SPEED
	velocity.z = direction.z * MOVEMENT_SPEED

	anim_tree.set("parameters/conditions/is_walking", is_walking)
	anim_tree.set("parameters/conditions/is_not_walking", !is_walking)

	move_and_slide()
