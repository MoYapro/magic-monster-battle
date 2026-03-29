class_name BiomesData

# Biome grid axes:
#   x = 0 (hot / dry)  <------>  10 (wet / cold)
#   y = 0 (real)       <------>  10 (fantasy)
#
#        0    1    2    3    4    5    6    7    8    9   10
#  0         Desert              Forest       Mountain Tundra
#  1         Volcano                               ...
#  2
#  3                   Swamp
#  4
#  5                        Cave
#  6                                  Ruins
#  ...

static var _all: Array[BiomeData] = []


static func all() -> Array[BiomeData]:
	if _all.is_empty():
		_all = _build()
	return _all


static func get_by_name(biome_name: String) -> BiomeData:
	for biome: BiomeData in all():
		if biome.name == biome_name:
			return biome
	return null


static func neighbors(biome: BiomeData) -> Array[BiomeData]:
	return all().filter(func(b: BiomeData) -> bool: return b != biome)


static func stray_pool(biome: BiomeData) -> Array[BiomeData]:
	var result: Array[BiomeData] = []
	for b: BiomeData in all():
		if b == biome:
			continue
		if BiomeData.stray_weight(biome, b) > 0.0:
			result.append(b)
	return result


static func _build() -> Array[BiomeData]:
	var desert   := BiomeData.new("Desert",   "The heat breaks minds before bodies.",  Color(0.85, 0.60, 0.15), Vector2i(1, 0))
	var volcano  := BiomeData.new("Volcano",  "The earth itself is your enemy.",       Color(0.85, 0.25, 0.10), Vector2i(1, 1))
	var forest   := BiomeData.new("Forest",   "Ancient trees hide ancient dangers.",   Color(0.15, 0.55, 0.20), Vector2i(4, 1))
	var mountain := BiomeData.new("Mountain", "The summit demands a toll.",            Color(0.55, 0.55, 0.60), Vector2i(7, 1))
	var tundra   := BiomeData.new("Tundra",   "Cold enough to numb courage.",          Color(0.45, 0.65, 0.85), Vector2i(9, 0))
	var swamp    := BiomeData.new("Swamp",    "Nothing enters here and leaves clean.", Color(0.25, 0.50, 0.30), Vector2i(3, 3))
	var cave     := BiomeData.new("Cave",     "Darkness is the least of your fears.",  Color(0.30, 0.25, 0.40), Vector2i(5, 5))
	var ruins    := BiomeData.new("Ruins",    "Something still walks these halls.",    Color(0.55, 0.45, 0.35), Vector2i(7, 6))

	desert.monster_pool   = [Goblin, Skeleton, Scorpion]
	volcano.monster_pool  = [Goblin, ShieldOgre, FireElemental, WarDrummer]
	forest.monster_pool   = [Goblin, Troll, Treant, WraithBlade, ShadowPanther, GroveTender]
	mountain.monster_pool = [Troll, ShieldOgre, StoneGiant, WarDrummer]
	tundra.monster_pool   = [Skeleton, Troll, FrostMage, Banshee]
	swamp.monster_pool    = [Goblin, Witch, Troll, BogShambler, ShadowPanther, GroveTender]
	cave.monster_pool     = [Goblin, Troll, ShieldOgre, CaveSpider, WraithBlade]
	ruins.monster_pool    = [Skeleton, Witch, ShieldOgre, CursedKnight, Banshee, BoneCaller, WarDrummer, FallenPaladin]

	desert.obstacle_pool   = [Stone, Boulder, Barrel, Cactus, SandDune, Obelisk]
	volcano.obstacle_pool  = [Stone, Boulder, Barrel, LavaRock, ObsidianSpike, AshPile]
	forest.obstacle_pool   = [ObstacleTree, Log, Stone, Thornbush, AncientStump, MushroomCircle]
	mountain.obstacle_pool = [Boulder, Stone, Monolith, IceBlock, Stalagmite, SnowDrift]
	tundra.obstacle_pool   = [Stone, Boulder, Log, IceWall, FrozenLog, GlacierChunk]
	swamp.obstacle_pool    = [Log, ObstacleTree, Barrel, Mudpit, RottedStump, BogPillar]
	cave.obstacle_pool     = [Stone, Boulder, Monolith, StalactitePillar, CrystalFormation, BonePile]
	ruins.obstacle_pool    = [Monolith, Stone, Barrel, BrokenPillar, Altar, Sarcophagus]

	return [desert, volcano, forest, mountain, tundra, swamp, cave, ruins]
