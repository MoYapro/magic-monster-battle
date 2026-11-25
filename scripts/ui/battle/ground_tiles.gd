class_name GroundTiles
extends RefCounted
## Which ground tile (assets/grounds/<name>.png) each battlefield cell shows.

const DIR := "res://assets/grounds/"
const DEFAULT_BASE: Array[String] = ["dirt_1", "dirt_2", "mud_1"]
const BIOME_BASE := {
	"Desert": ["sand_1", "sand_2", "sand_1", "dirt_1"],
	"Tundra": ["snow_1", "snow_2", "snow_1", "stone_1"],
	"Forest": ["grass_1", "grass_2", "dirt_1", "grass_1"],
	"Swamp": ["mud_1", "mud_2", "grass_2", "mud_1"],
	"Mountain": ["stone_1", "stone_2", "dirt_2", "stone_1"],
	"Pyramids": ["sand_1", "sand_2", "stone_2"],
	"Coast": ["sand_1", "sand_2", "grass_2"],
	"Glacial Temple": ["snow_1", "snow_2", "stone_2"],
	"Frozen Shipwreck": ["snow_1", "snow_2", "dirt_2"],
	"Jungle": ["grass_1", "grass_2", "mud_1"],
	"Graveyard": ["dirt_1", "dirt_2", "mud_2", "grass_1"],
	"Ruins": ["stone_1", "stone_2", "dirt_1"],
	"Cave": ["stone_1", "stone_2", "dirt_1", "mud_1"],
	"Volcano": ["stone_2", "dirt_2", "stone_1"],
	"Hell": ["dirt_2", "stone_2", "mud_2"],
	"Astral Plane": ["stone_1", "snow_1", "stone_2"],
	"Underwater": ["sand_2", "mud_1", "stone_1"],
	"The Source": ["stone_1", "stone_2"],
}
const STATE_TILE := {GroundType.Type.PUDDLE: "wet"}

static var _textures: Dictionary = {}


static func base_for_biome(biome_name: String) -> Array[String]:
	var out: Array[String] = []
	out.assign(BIOME_BASE.get(biome_name, DEFAULT_BASE))
	return out


## State grounds (puddle -> wet) replace the base; otherwise a stable pick from the base mix.
static func tile_for(base: Array[String], ground: GroundType.Type, cell: Vector2i) -> String:
	if STATE_TILE.has(ground):
		return STATE_TILE[ground]
	if base.is_empty():
		return DEFAULT_BASE[0]
	return base[(cell.x * 7 + cell.y * 13 + cell.x * cell.y) % 97 % base.size()]


static func texture(tile_name: String) -> Texture2D:
	if not _textures.has(tile_name):
		var path := DIR + tile_name + ".png"
		_textures[tile_name] = load(path) if ResourceLoader.exists(path) else null
	return _textures[tile_name]
