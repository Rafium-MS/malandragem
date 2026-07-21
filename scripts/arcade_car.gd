class_name ArcadeCar
extends CharacterBody3D

@export_category("Motor")
@export var max_forward_speed := 22.0
@export var max_reverse_speed := 8.0
@export var engine_acceleration := 12.0
@export var reverse_acceleration := 8.0
@export var rolling_drag := 5.0
@export var brake_strength := 28.0

@export_category("Direcao")
@export var steering_speed := 1.8
@export var minimum_steering_speed := 0.5
@export var high_speed_steering_factor := 0.4

@export_category("Camera")
@export var mouse_sensitivity := 0.0025
@export var camera_smooth_speed := 14.0

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var front_left: Node3D = $Visual/FrontLeftWheel
@onready var front_right: Node3D = $Visual/FrontRightWheel
@onready var exit_point: Marker3D = $ExitPoint

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_speed := 0.0
var _driver: Node3D
var _camera_yaw := 0.0
var _camera_pitch := deg_to_rad(-10.0)


func _ready() -> void:
	add_to_group("vehicles")
	camera.current = false


func _unhandled_input(event: InputEvent) -> void:
	if _driver == null:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_camera_yaw -= event.relative.x * mouse_sensitivity
		_camera_pitch = clamp(
			_camera_pitch - event.relative.y * mouse_sensitivity,
			deg_to_rad(-40.0),
			deg_to_rad(45.0)
		)


func _process(delta: float) -> void:
	if _driver == null:
		return
	var weight := 1.0 - exp(-camera_smooth_speed * delta)
	camera_pivot.rotation.y = lerp_angle(camera_pivot.rotation.y, _camera_yaw, weight)
	camera_pivot.rotation.x = lerp_angle(camera_pivot.rotation.x, _camera_pitch, weight)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.5

	if _driver != null:
		_apply_engine(delta)
		_apply_steering(delta)
	else:
		current_speed = move_toward(current_speed, 0.0, rolling_drag * delta)

	var forward := -global_transform.basis.z
	velocity.x = forward.x * current_speed
	velocity.z = forward.z * current_speed
	move_and_slide()

	for index in get_slide_collision_count():
		var collision := get_slide_collision(index)
		if absf(collision.get_normal().y) < 0.5:
			current_speed *= 0.35
			break


func _apply_engine(delta: float) -> void:
	var throttle := Input.get_axis("move_back", "move_forward")
	if Input.is_action_pressed("jump"):
		current_speed = move_toward(current_speed, 0.0, brake_strength * delta)
	elif throttle > 0.0:
		current_speed = move_toward(current_speed, max_forward_speed, engine_acceleration * throttle * delta)
	elif throttle < 0.0:
		current_speed = move_toward(current_speed, -max_reverse_speed, reverse_acceleration * -throttle * delta)
	else:
		current_speed = move_toward(current_speed, 0.0, rolling_drag * delta)


func _apply_steering(delta: float) -> void:
	var steering_input := Input.get_axis("move_left", "move_right")
	if absf(current_speed) < minimum_steering_speed:
		steering_input = 0.0

	var speed_ratio := clampf(absf(current_speed) / max_forward_speed, 0.0, 1.0)
	var steering_factor := lerpf(1.0, high_speed_steering_factor, speed_ratio)
	var reverse_direction := signf(current_speed)
	rotate_y(-steering_input * steering_speed * steering_factor * reverse_direction * delta)
	front_left.rotation.y = lerp(front_left.rotation.y, -steering_input * 0.45, 10.0 * delta)
	front_right.rotation.y = lerp(front_right.rotation.y, -steering_input * 0.45, 10.0 * delta)


func can_enter() -> bool:
	return _driver == null and absf(current_speed) < 2.0


func set_driver(player: Node3D) -> void:
	_driver = player
	_camera_yaw = 0.0
	_camera_pitch = deg_to_rad(-10.0)
	camera_pivot.rotation = Vector3(_camera_pitch, 0.0, 0.0)
	camera.current = true


func remove_driver() -> void:
	_driver = null
	camera.current = false


func get_exit_position() -> Vector3:
	return exit_point.global_position
