class_name MageColors
extends RefCounted
## Portrait colour per mage (presentation only; MageData has no colour).

const KNOWN := {"Lyra": Color("#e07a3a"), "Eron": Color("#6aa0d8"), "Vael": Color("#7fbf5a")}
const FALLBACK: Array[Color] = [Color("#d9a032"), Color("#b07ad8"), Color("#d86a8a"), Color("#5ac8b8")]


static func color_for(mage_name: String) -> Color:
	if KNOWN.has(mage_name):
		return KNOWN[mage_name]
	return FALLBACK[absi(hash(mage_name)) % FALLBACK.size()]
