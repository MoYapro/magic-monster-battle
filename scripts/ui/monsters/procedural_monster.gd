class_name ProceduralMonster
extends Node2D
## A monster assembled from its exported body parts and animated with tweens.
## The node's origin is the bottom centre of the monster's footprint.

signal animation_finished(anim: StringName)

const SCENE_PATH := "res://scenes/monsters/procedural_monster.tscn"

var rig: MonsterRig
var parts: Dictionary[String, Node2D] = {}
var _animator: MonsterAnimator
var _idle: Tween
var _action: Tween
var _dying := false

@onready var _pose: Node2D = $Pose
@onready var _body: Node2D = $Pose/Body


## New monster for the art id, fitted to `display_size`; null when the monster has no rig yet.
static func create(art_id: String, display_size: Vector2) -> ProceduralMonster:
	var r := MonsterRig.load_for(art_id)
	if r == null:
		return null
	var m: ProceduralMonster = (load(SCENE_PATH) as PackedScene).instantiate()
	m.rig = r
	m.scale = Vector2.ONE * (display_size.x / r.canvas_size.x)
	return m


func _ready() -> void:
	_body.position = Vector2(-rig.canvas_size.x / 2.0, -rig.canvas_size.y)
	parts = MonsterRigBuilder.build(rig, _body)
	_animator = MonsterAnimator.new(_pose, parts, hash(rig.id))
	play(&"idle_breathing")


func fit(display_size: Vector2) -> void:
	scale = Vector2.ONE * (display_size.x / rig.canvas_size.x)


func play(anim: StringName) -> void:
	if _dying:
		return
	match anim:
		&"idle_breathing":
			if _idle:
				_idle.kill()
			_idle = _animator.idle_breathing()
		&"attack", &"take_hit", &"die":
			_play_action(anim)


func _play_action(anim: StringName) -> void:
	if _action and _action.is_running():
		_action.custom_step(10.0)  # finish the previous action at once so poses never stack
	_dying = anim == &"die"
	if _dying and _idle:
		_idle.kill()
	_action = _animator.call(anim)
	_action.finished.connect(func() -> void: animation_finished.emit(anim))
