class_name ObstacleArt
extends RefCounted
## Linocut images of the obstacles (assets/obstacles/<id>.png, 256 px per grid cell), exported
## from layout-drafts/obstacles by tools/export_art.py.

const DIR := "res://assets/obstacles/"

static var _textures: Dictionary = {}


## Art id of an obstacle: the file name of its script (bog_pillar.gd -> "bog_pillar").
static func art_id(obs: ObstacleData) -> String:
	var script: Script = obs.get_script()
	return script.resource_path.get_file().get_basename() if script else ""


static func texture(obs: ObstacleData) -> Texture2D:
	var id := art_id(obs)
	if not _textures.has(id):
		var path := DIR + id + ".png"
		_textures[id] = load(path) if ResourceLoader.exists(path) else null
	return _textures[id]
