class_name Pedestrian
extends CharacterBody3D

signal movement_state_changed(state: StringName)

@export_category("Rota")
@export var patrol_points := PackedVector3Array([
	Vector3.ZERO,
	Vector3(0, 0, 12),
	Vector3(0, 0, 24),
])
@export var walk_speed := 2.2
@export var acceleration := 8.0
@export var arrival_distance := 0.45
@export var wait_time := 1.2

@export_category("Percepcao")
@export var vehicle_danger_speed := 2.5

@onready var visual: Node3D = $Visual
@onready var obstacle_ray: RayCast3D = $Visual/ObstacleRay
@onready var vehicle_detector: Area3D = $VehicleDetector

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _route_origin: Vector3
var _target_index := 1
var _wait_timer := 0.0
var _movement_state: StringName = &"idle"
var _nearby_vehicles: Array[Node3D] = []


func _ready() -> void:
	_route_origin = global_position
	vehicle_detector.body_entered.connect(_on_detector_body_entered)
	vehicle_detector.body_exited.connect(_on_detector_body_exited)


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_remove_invalid_vehicles()

	if _must_wait_for_safety() or obstacle_ray.is_colliding():
		_slow_down(delta)
		_set_movement_state(&"idle")
		move_and_slide()
		return

	if _wait_timer > 0.0:
		_wait_timer -= delta
		_slow_down(delta)
		_set_movement_state(&"idle")
		move_and_slide()
		return

	if patrol_points.is_empty():
		_slow_down(delta)
		_set_movement_state(&"idle")
		move_and_slide()
		return

	var target := _route_origin + patrol_points[_target_index]
	var offset := target - global_position
	offset.y = 0.0
	if offset.length() <= arrival_distance:
		_target_index = (_target_index + 1) % patrol_points.size()
		_wait_timer = wait_time
		_slow_down(delta)
		_set_movement_state(&"idle")
		move_and_slide()
		return

	var direction := offset.normalized()
	velocity.x = move_toward(velocity.x, direction.x * walk_speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, direction.z * walk_speed, acceleration * delta)
	var target_yaw := atan2(direction.x, direction.z)
	visual.rotation.y = lerp_angle(visual.rotation.y, target_yaw, 10.0 * delta)
	_set_movement_state(&"walk")
	move_and_slide()


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.5


func _slow_down(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
	velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)


func _must_wait_for_safety() -> bool:
	for vehicle in _nearby_vehicles:
		var speed_value: Variant = vehicle.get("current_speed")
		if speed_value is float and absf(speed_value) >= vehicle_danger_speed:
			return true
	return false


func _remove_invalid_vehicles() -> void:
	_nearby_vehicles = _nearby_vehicles.filter(func(vehicle: Node3D) -> bool:
		return is_instance_valid(vehicle)
	)


func _set_movement_state(state: StringName) -> void:
	if state == _movement_state:
		return
	_movement_state = state
	movement_state_changed.emit(_movement_state)


func _on_detector_body_entered(body: Node3D) -> void:
	if body.is_in_group("vehicles") and body not in _nearby_vehicles:
		_nearby_vehicles.append(body)


func _on_detector_body_exited(body: Node3D) -> void:
	_nearby_vehicles.erase(body)
