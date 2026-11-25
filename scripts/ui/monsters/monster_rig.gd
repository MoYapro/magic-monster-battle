class_name MonsterRig
extends RefCounted
## Cut-out rig of a monster exported by tools/export_art.py (assets/monsters/<id>/rig.json).

const ART_DIR := "res://assets/monsters/"

var id: String
var canvas_size: Vector2       # rig pixels; one grid cell is canvas_size / cells
var cells: Vector2i
var joints: Array[RigJoint] = []  # parents before children
var layers: Array[RigLayer] = []


static func from_json(text: String) -> MonsterRig:
	var json := JSON.new()
	if json.parse(text) != OK or not json.data is Dictionary:
		return null
	var data: Dictionary = json.data
	var rig := MonsterRig.new()
	rig.id = data.get("id", "")
	rig.canvas_size = _vec(data.get("canvas", [0, 0]))
	rig.cells = Vector2i(_vec(data.get("cells", [1, 1])))
	for j: Dictionary in data.get("joints", []):
		rig.joints.append(RigJoint.new(j["name"], _vec(j["pivot"]), j.get("parent", "")))
	for l: Dictionary in data.get("layers", []):
		rig.layers.append(RigLayer.new(l["file"], l["joint"], int(l["z"]), _vec(l["pos"])))
	return rig


static func load_for(art_id: String) -> MonsterRig:
	var path := ART_DIR + art_id + "/rig.json"
	if not FileAccess.file_exists(path):
		return null
	return from_json(FileAccess.get_file_as_string(path))


## Art id of an enemy: the file name of its monster script (goblin.gd -> "goblin").
static func art_id_for(enemy: EnemyData) -> String:
	var script: Script = enemy.get_script()
	return script.resource_path.get_file().get_basename() if script else ""


static func full_texture(art_id: String) -> Texture2D:
	var path := ART_DIR + art_id + "/full.png"
	return load(path) if ResourceLoader.exists(path) else null


func texture_path(layer: RigLayer) -> String:
	return ART_DIR + id + "/" + layer.file


func joint(joint_name: String) -> RigJoint:
	for j in joints:
		if j.name == joint_name:
			return j
	return null


static func _vec(a: Array) -> Vector2:
	return Vector2(float(a[0]), float(a[1]))
