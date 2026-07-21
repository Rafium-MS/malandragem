class_name PlayerController
extends CharacterBody3D

signal movement_state_changed(state: StringName)

@export_category("Movimento")
@export var walk_speed := 5.0
@export var sprint_speed := 9.0
@export var ground_acceleration := 28.0
@export var ground_deceleration := 34.0
@export_range(0.0, 1.0, 0.05) var air_control := 0.35
@export var jump_velocity := 7.0
@export_range(0.0, 0.5, 0.01) var coyote_time := 0.12
@export_range(0.0, 0.5, 0.01) var jump_buffer_time := 0.12
@export var visual_turn_speed := 14.0

@export_category("Interacao")
@export var interaction_distance := 3.0

@export_category("Camera")
@export var mouse_sensitivity := 0.0025
@export var camera_smooth_speed := 18.0
@export_range(-80.0, 0.0, 1.0) var min_pitch_degrees := -55.0
@export_range(0.0, 80.0, 1.0) var max_pitch_degrees := 65.0
@export var min_zoom := 2.5
@export var max_zoom := 7.0
@export var zoom_step := 0.75
@export var zoom_smooth_speed := 12.0
@export var normal_fov := 70.0
@export var sprint_fov := 76.0

@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var visual: Node3D = $Visual
@onready var body_collision: CollisionShape3D = $CollisionShape3D

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _target_camera_yaw := 0.0
var _target_camera_pitch := deg_to_rad(-12.0)
var _target_zoom := 5.0
var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0
var _movement_state: StringName = &"idle"
var _current_vehicle: Node3D


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_target_zoom = clamp(spring_arm.spring_length, min_zoom, max_zoom)
	camera_pivot.rotation = Vector3(_target_camera_pitch, _target_camera_yaw, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if is_instance_valid(_current_vehicle):
			_exit_current_vehicle()
		else:
			_try_enter_nearest_vehicle()
		get_viewport().set_input_as_handled()
		return

	if is_instance_valid(_current_vehicle):
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_target_camera_yaw -= event.relative.x * mouse_sensitivity
		_target_camera_pitch -= event.relative.y * mouse_sensitivity
		_target_camera_pitch = clamp(
			_target_camera_pitch,
			deg_to_rad(min_pitch_degrees),
			deg_to_rad(max_pitch_degrees)
		)

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_target_zoom = max(min_zoom, _target_zoom - zoom_step)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_target_zoom = min(max_zoom, _target_zoom + zoom_step)
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event.is_action_pressed("jump"):
		_jump_buffer_timer = jump_buffer_time

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _process(delta: float) -> void:
	if is_instance_valid(_current_vehicle):
		return

	var camera_weight := 1.0 - exp(-camera_smooth_speed * delta)
	camera_pivot.rotation.y = lerp_angle(camera_pivot.rotation.y, _target_camera_yaw, camera_weight)
	camera_pivot.rotation.x = lerp_angle(camera_pivot.rotation.x, _target_camera_pitch, camera_weight)

	var zoom_weight := 1.0 - exp(-zoom_smooth_speed * delta)
	spring_arm.spring_length = lerp(spring_arm.spring_length, _target_zoom, zoom_weight)

	var target_fov := sprint_fov if Input.is_action_pressed("sprint") and _horizontal_speed() > walk_speed else normal_fov
	camera.fov = lerp(camera.fov, target_fov, camera_weight)


func _physics_process(delta: float) -> void:
	if is_instance_valid(_current_vehicle):
		global_position = _current_vehicle.global_position
		velocity = Vector3.ZERO
		return

	_update_jump_timers(delta)
	_apply_gravity_and_jump(delta)

	var input_vector := Input.get_vector(
		"move_left", "move_right", "move_forward", "move_back"
	)
	var camera_basis := Basis(Vector3.UP, camera_pivot.rotation.y)
	var direction := (camera_basis * Vector3(input_vector.x, 0.0, input_vector.y)).normalized()
	var target_speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	var target_horizontal := direction * target_speed
	var rate := ground_acceleration if not direction.is_zero_approx() else ground_deceleration
	if not is_on_floor():
		rate *= air_control

	velocity.x = move_toward(velocity.x, target_horizontal.x, rate * delta)
	velocity.z = move_toward(velocity.z, target_horizontal.z, rate * delta)

	if not direction.is_zero_approx():
		var target_visual_yaw := atan2(direction.x, direction.z)
		var turn_weight := 1.0 - exp(-visual_turn_speed * delta)
		visual.rotation.y = lerp_angle(visual.rotation.y, target_visual_yaw, turn_weight)

	move_and_slide()
	_update_movement_state(direction)


func _update_jump_timers(delta: float) -> void:
	_jump_buffer_timer = maxf(_jump_buffer_timer - delta, 0.0)
	if is_on_floor():
		_coyote_timer = coyote_time
	else:
		_coyote_timer = maxf(_coyote_timer - delta, 0.0)


func _apply_gravity_and_jump(delta: float) -> void:
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = jump_velocity
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0
	elif not is_on_floor():
		velocity.y -= gravity * delta

	# Soltar Espaco cedo produz um pulo mais curto.
	if Input.is_action_just_released("jump") and velocity.y > 0.0:
		velocity.y *= 0.5


func _update_movement_state(direction: Vector3) -> void:
	var next_state: StringName
	if not is_on_floor():
		next_state = &"jump" if velocity.y > 0.0 else &"fall"
	elif direction.is_zero_approx():
		next_state = &"idle"
	elif Input.is_action_pressed("sprint"):
		next_state = &"sprint"
	else:
		next_state = &"walk"

	if next_state != _movement_state:
		_movement_state = next_state
		movement_state_changed.emit(_movement_state)


func _horizontal_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()


func _try_enter_nearest_vehicle() -> void:
	var nearest_vehicle: Node3D
	var nearest_distance := interaction_distance
	for candidate in get_tree().get_nodes_in_group("vehicles"):
		if not candidate is Node3D or not candidate.has_method("set_driver"):
			continue
		var distance := global_position.distance_to(candidate.global_position)
		if distance <= nearest_distance and candidate.call("can_enter"):
			nearest_vehicle = candidate
			nearest_distance = distance

	if nearest_vehicle == null:
		return

	_current_vehicle = nearest_vehicle
	velocity = Vector3.ZERO
	visual.visible = false
	body_collision.set_deferred("disabled", true)
	camera.current = false
	_current_vehicle.call("set_driver", self)


func _exit_current_vehicle() -> void:
	var vehicle := _current_vehicle
	_current_vehicle = null
	global_position = vehicle.call("get_exit_position")
	vehicle.call("remove_driver")
	visual.visible = true
	body_collision.set_deferred("disabled", false)
	camera.current = true
