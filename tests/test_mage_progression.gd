extends GutTest


func _mage(max_hp: int, current_hp: int, mana: int = 5) -> MageData:
	var m := MageData.new("M", max_hp, mana)
	m.current_hp = current_hp
	return m


func test_hp_upgrade_raises_max_and_current() -> void:
	var m := _mage(50, 40)
	MageProgression.apply_upgrade(m, "hp")
	assert_eq(m.max_hp, 60)
	assert_eq(m.current_hp, 50)


func test_hp_upgrade_at_full_hp_stays_full() -> void:
	var m := _mage(50, 50)
	MageProgression.apply_upgrade(m, "hp")
	assert_eq(m.current_hp, 60)


func test_hp_upgrade_on_dead_mage_grants_gain() -> void:
	var m := _mage(50, 0)
	MageProgression.apply_upgrade(m, "hp")
	assert_eq(m.current_hp, 10)


func test_hp_upgrade_leaves_mana_alone() -> void:
	var m := _mage(50, 40, 3)
	MageProgression.apply_upgrade(m, "hp")
	assert_eq(m.mana_allowance, 3)


func test_mana_upgrade_adds_one() -> void:
	var m := _mage(50, 40, 3)
	MageProgression.apply_upgrade(m, "mana")
	assert_eq(m.mana_allowance, 4)
	assert_eq(m.max_hp, 50)
	assert_eq(m.current_hp, 40)


func test_unknown_stat_upgrades_mana() -> void:
	var m := _mage(50, 40, 3)
	MageProgression.apply_upgrade(m, "other")
	assert_eq(m.mana_allowance, 4)


func test_dead_mage_revives_at_30_percent() -> void:
	assert_eq(MageProgression.healed_hp(_mage(50, 0)), 15)


func test_negative_hp_counts_as_dead() -> void:
	assert_eq(MageProgression.healed_hp(_mage(50, -7)), 15)


func test_revive_truncates() -> void:
	assert_eq(MageProgression.healed_hp(_mage(55, 0)), 16)


func test_alive_mage_heals_80_percent() -> void:
	assert_eq(MageProgression.healed_hp(_mage(100, 10)), 90)


func test_heal_capped_at_max() -> void:
	assert_eq(MageProgression.healed_hp(_mage(100, 30)), 100)


func test_heal_truncates() -> void:
	assert_eq(MageProgression.healed_hp(_mage(33, 1)), 27)


func test_heal_all_applies_to_every_mage() -> void:
	var mages: Array[MageData] = [_mage(50, 0), _mage(100, 10), _mage(40, 40)]
	MageProgression.heal_all(mages)
	assert_eq(mages[0].current_hp, 15)
	assert_eq(mages[1].current_hp, 90)
	assert_eq(mages[2].current_hp, 40)
