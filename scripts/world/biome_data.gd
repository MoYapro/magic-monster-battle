class_name BiomeData

var name: String
var tagline: String
var color: Color


func _init(p_name: String, p_tagline: String, p_color: Color) -> void:
	name = p_name
	tagline = p_tagline
	color = p_color


static func all() -> Array[BiomeData]:
	return [
		BiomeData.new("Forest",   "Ancient trees hide ancient dangers.",  Color(0.15, 0.55, 0.20)),
		BiomeData.new("Desert",   "The heat breaks minds before bodies.",  Color(0.85, 0.60, 0.15)),
		BiomeData.new("Ruins",    "Something still walks these halls.",    Color(0.55, 0.45, 0.35)),
		BiomeData.new("Swamp",    "Nothing enters here and leaves clean.", Color(0.25, 0.50, 0.30)),
		BiomeData.new("Volcano",  "The earth itself is your enemy.",       Color(0.85, 0.25, 0.10)),
		BiomeData.new("Tundra",   "Cold enough to numb courage.",          Color(0.45, 0.65, 0.85)),
		BiomeData.new("Cave",     "Darkness is the least of your fears.",  Color(0.30, 0.25, 0.40)),
		BiomeData.new("Mountain", "The summit demands a toll.",            Color(0.55, 0.55, 0.60)),
	]
