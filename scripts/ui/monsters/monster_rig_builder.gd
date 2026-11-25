class_name MonsterRigBuilder
extends RefCounted
## Builds the node tree of a rig: one Node2D per joint (placed at its pivot, nested under its
## parent joint) holding one Sprite2D per exported layer. Returns joint nodes by name.


## Adds the joints under `body` (whose origin is the rig canvas' top-left).
static func build(rig: MonsterRig, body: Node2D) -> Dictionary[String, Node2D]:
	var joints: Dictionary[String, Node2D] = {}
	for j in rig.joints:
		var node := Node2D.new()
		node.name = j.name
		var parent := rig.joint(j.parent) if not j.parent.is_empty() else null
		node.position = j.pivot - (parent.pivot if parent else Vector2.ZERO)
		(joints[j.parent] if parent and joints.has(j.parent) else body).add_child(node)
		joints[j.name] = node
	for layer in rig.layers:
		_add_layer(rig, layer, joints)
	return joints


static func _add_layer(rig: MonsterRig, layer: RigLayer, joints: Dictionary[String, Node2D]) -> void:
	var joint := rig.joint(layer.joint)
	if joint == null or not joints.has(layer.joint):
		return
	var sprite := Sprite2D.new()
	sprite.texture = load(rig.texture_path(layer))
	sprite.centered = false
	sprite.position = layer.pos - joint.pivot
	sprite.z_index = layer.z  # rims (low z) stay below every body part of this monster
	joints[layer.joint].add_child(sprite)
