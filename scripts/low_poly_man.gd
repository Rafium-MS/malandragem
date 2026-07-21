class_name LowPolyMan
extends Node3D

@export var walk_frequency := 8.0
@export var sprint_frequency := 12.0
@export var walk_swing := 0.55
@export var sprint_swing := 0.9
@export var pose_blend_speed := 12.0

@onready var torso: Node3D = $TorsoPivot
@onready var left_arm: Node3D = $LeftArm
@onready var right_arm: Node3D = $RightArm
@onready var left_leg: Node3D = $LeftLeg
@onready var right_leg: Node3D = $RightLeg

var _movement_state: StringName = &"idle"
var _animation_time := 0.0
var _base_position: Vector3


func _ready() -> void:
	_base_position = position
	var controller := get_parent().get_parent()
	if controller.has_signal("movement_state_changed"):
		controller.movement_state_changed.connect(_on_movement_state_changed)


func _process(delta: float) -> void:
	_animation_time += delta
	var frequency := 0.0
	var swing_amount := 0.0
	if _movement_state == &"walk":
		frequency = walk_frequency
		swing_amount = walk_swing
	elif _movement_state == &"sprint":
		frequency = sprint_frequency
		swing_amount = sprint_swing

	var limb_swing := sin(_animation_time * frequency) * swing_amount if frequency > 0.0 else 0.0
	var left_arm_target := limb_swing
	var right_arm_target := -limb_swing
	var left_leg_target := -limb_swing
	var right_leg_target := limb_swing
	var torso_target := 0.0
	var height_offset := 0.0

	if _movement_state == &"idle":
		height_offset = sin(_animation_time * 2.0) * 0.015
		left_arm_target = sin(_animation_time * 2.0) * 0.025
		right_arm_target = -left_arm_target
	elif _movement_state == &"sprint":
		torso_target = -0.12
		height_offset = absf(sin(_animation_time * frequency)) * 0.035
	elif _movement_state == &"jump":
		left_arm_target = -0.45
		right_arm_target = -0.45
		left_leg_target = 0.35
		right_leg_target = -0.2
		torso_target = -0.08
	elif _movement_state == &"fall":
		left_arm_target = 0.35
		right_arm_target = 0.35
		left_leg_target = -0.15
		right_leg_target = 0.2

	var weight := 1.0 - exp(-pose_blend_speed * delta)
	left_arm.rotation.x = lerp_angle(left_arm.rotation.x, left_arm_target, weight)
	right_arm.rotation.x = lerp_angle(right_arm.rotation.x, right_arm_target, weight)
	left_leg.rotation.x = lerp_angle(left_leg.rotation.x, left_leg_target, weight)
	right_leg.rotation.x = lerp_angle(right_leg.rotation.x, right_leg_target, weight)
	torso.rotation.x = lerp_angle(torso.rotation.x, torso_target, weight)
	position.y = lerp(position.y, _base_position.y + height_offset, weight)


func _on_movement_state_changed(state: StringName) -> void:
	_movement_state = state
	if state == &"walk" or state == &"sprint":
		_animation_time = 0.0
