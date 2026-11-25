class_name SpellRunes
extends RefCounted
## Rune letters for every spell (see layout-drafts/spell-runes): one letter, or two fused when the
## first letter is shared. Alchemy results reuse their recipe: catalyst, reactant A, reactant B.

const LETTERS := {
	"amplify": "A", "bomb": "BL", "bone": "BN", "corrupted": "C", "detonate": "DT",
	"distillation": "DS", "ember": "E", "fire_catalyst": "FR", "force_push": "FP", "frost": "FS",
	"conductor": "G", "harmony": "H", "lightning": "LG", "line": "LN", "pierce": "P",
	"reactive": "R", "scorch_mark": "SM", "sunder": "SH", "shield": "SL", "single": "SN",
	"splash": "SP", "toxin_edge": "T", "venom": "V",
}
const BOLT_LETTERS := "BT"
const ALCHEMY := {
	"steam": ["FR", "FR", "FS"], "flame_burst": ["FR", "E", "E"], "curse": ["FR", "BN", "V"],
	"ice_cube": ["FP", "FS", "FS"], "soap": ["FP", "BN", "FS"],
}


static func letters(spell_id: String) -> String:
	if spell_id.begins_with("bolt_"):
		return BOLT_LETTERS
	return LETTERS.get(spell_id, "")


static func alchemy(spell_id: String) -> PackedStringArray:
	return PackedStringArray(ALCHEMY.get(spell_id, []))


static func is_bolt(spell_id: String) -> bool:
	return spell_id.begins_with("bolt_")
