class_name MageProgression

const HP_GAIN := 10
const MANA_GAIN := 1
const REVIVE_FRACTION := 0.3
const HEAL_FRACTION := 0.8


static func apply_upgrade(mage: MageData, stat: String) -> void:
	if stat == "hp":
		mage.max_hp += HP_GAIN
		mage.current_hp = mini(mage.max_hp, mage.current_hp + HP_GAIN)
	else:
		mage.mana_allowance += MANA_GAIN


static func healed_hp(mage: MageData) -> int:
	if mage.current_hp <= 0:
		return int(mage.max_hp * REVIVE_FRACTION)
	var heal := int(mage.max_hp * HEAL_FRACTION)
	return mini(mage.max_hp, mage.current_hp + heal)


static func heal_all(mages: Array[MageData]) -> void:
	for mage: MageData in mages:
		mage.current_hp = healed_hp(mage)
