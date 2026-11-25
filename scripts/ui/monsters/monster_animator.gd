class_name MonsterAnimator
extends RefCounted
## Tween-driven cut-out animations. `pose` is a node whose origin is at the monster's feet; the
## whole figure leans, lunges and scales around it, and single parts add small motions on top.

const FACING := -1.0  # monsters face left, towards the mages

var pose: Node2D
var joints: Dictionary[String, Node2D]
var head: Node2D
var weapons: Array[Node2D] = []
var _rest: Dictionary = {}  # node -> [position, rotation, scale]
var _rng := RandomNumberGenerator.new()


func _init(p_pose: Node2D, p_joints: Dictionary[String, Node2D], seed_value: int) -> void:
	pose = p_pose
	joints = p_joints
	_rng.seed = seed_value
	var names: Array[String] = []
	names.assign(joints.keys())
	head = joints.get(MonsterParts.head(names))
	for w in MonsterParts.weapons(names):
		weapons.append(joints[w])
	for n: Node2D in [pose] + joints.values():
		_rest[n] = [n.position, n.rotation, n.scale]


func idle_breathing() -> Tween:
	var t := pose.create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var period := 1.4 + _rng.randf() * 0.4
	t.tween_interval(_rng.randf() * 0.4)  # uneven pause between breaths so monsters drift out of sync
	t.tween_property(pose, "scale", Vector2(0.99, 1.025), period)
	if head:
		t.parallel().tween_property(head, "position", _rest_pos(head) + Vector2(0, -3), period)
	t.tween_property(pose, "scale", Vector2.ONE, period)
	if head:
		t.parallel().tween_property(head, "position", _rest_pos(head), period)
	return t


func attack() -> Tween:
	var t := pose.create_tween().set_trans(Tween.TRANS_QUAD)
	t.tween_property(pose, "rotation", 0.08 * -FACING, 0.16).set_ease(Tween.EASE_OUT)
	_swing(t, -0.5, 0.16)
	t.tween_property(pose, "position", _rest_pos(pose) + Vector2(22 * FACING, 0), 0.1).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(pose, "rotation", 0.06 * FACING, 0.1)
	_swing(t, 0.45, 0.1)
	t.tween_interval(0.06)
	t.tween_property(pose, "position", _rest_pos(pose), 0.24).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(pose, "rotation", 0.0, 0.24)
	_swing(t, 0.0, 0.24)
	return t


func _swing(t: Tween, angle: float, time: float) -> void:
	for w in weapons:
		t.parallel().tween_property(w, "rotation", _rest[w][1] + angle, time)


func take_hit() -> Tween:
	var t := pose.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	pose.modulate = Color(2.2, 2.2, 2.2)  # values above 1 brighten: a white flash
	t.tween_property(pose, "modulate", Color(1.6, 0.45, 0.4), 0.08)
	t.parallel().tween_property(pose, "position", _rest_pos(pose) + Vector2(-14 * FACING, 0), 0.08)
	for n in _jitter_parts(3):
		t.parallel().tween_property(n, "rotation", _rest[n][1] + _rng.randf_range(-0.18, 0.18), 0.08)
	t.tween_property(pose, "modulate", Color.WHITE, 0.22)
	t.parallel().tween_property(pose, "position", _rest_pos(pose), 0.22)
	for n in _jitter_parts(3):
		t.parallel().tween_property(n, "rotation", _rest[n][1], 0.22)
	return t


## Parts drop and tumble one after another while the figure fades out.
func die() -> Tween:
	var t := pose.create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	var i := 0
	for n: String in joints:
		if MonsterParts.is_static(n):
			continue
		var node := joints[n]
		var delay := i * 0.025
		t.tween_property(node, "position", node.position + Vector2(_rng.randf_range(-20, 20), _rng.randf_range(18, 60)), 0.5).set_delay(delay)
		t.tween_property(node, "rotation", node.rotation + _rng.randf_range(-0.9, 0.9), 0.5).set_delay(delay)
		i += 1
	t.tween_property(pose, "modulate:a", 0.0, 0.45).set_delay(0.25)
	return t


func _jitter_parts(count: int) -> Array[Node2D]:
	var out: Array[Node2D] = []
	var nodes := joints.values()
	for k in mini(count, nodes.size()):
		out.append(nodes[(k * 7 + 3) % nodes.size()])
	return out


func _rest_pos(n: Node2D) -> Vector2:
	return _rest[n][0]
