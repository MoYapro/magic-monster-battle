class_name LootInventory extends RefCounted

# Loot-screen rules over the run's pending loot, backpack, wands and mages.
# Backed by `run` (the GameState autoload, or a fresh game_state.gd in tests);
# every read/write goes straight to it so the screen and GameState never diverge.

enum Area { NONE, LOOT, BACKPACK }

const BACKPACK_SLOTS := 24

var _run: Object

var pending_loot: Array[SpellData]:
	get: return _run.pending_loot
var backpack: Array[SpellData]:
	get: return _run.backpack
var battle_drops: Array[SpellData]:
	get: return _run.battle_drops
var pending_loot_wands: Array[WandData]:
	get: return _run.pending_loot_wands
var wands: Array[WandData]:
	get: return _run.wands
var mages: Array[MageData]:
	get: return _run.mages
var is_initial_setup: bool:
	get: return _run.is_initial_setup


func _init(run: Object) -> void:
	_run = run


# --- taking spells / wands out ---

func can_take_loot(index: int) -> bool:
	return LootRoller.can_pick(pending_loot[index], battle_drops, pending_loot)


# Returns null when the pick limit forbids taking this battle drop.
func take_loot(index: int) -> SpellData:
	if not can_take_loot(index):
		return null
	var spell := pending_loot[index]
	pending_loot.remove_at(index)
	return spell


func take_backpack(index: int) -> SpellData:
	var spell := backpack[index]
	backpack.remove_at(index)
	return spell


func take_loot_wand(index: int) -> WandData:
	var wand := pending_loot_wands[index]
	pending_loot_wands.remove_at(index)
	return wand


static func take_from_slot(slot: SpellSlotData) -> SpellData:
	var spell := slot.spell
	slot.spell = null
	return spell


func picks_used() -> int:
	return LootRoller.picks_used(battle_drops, pending_loot)


func backpack_has_room() -> bool:
	return backpack.size() < BACKPACK_SLOTS


# --- dropping spells ---

# Drop outside any wand slot: onto a panel, else back where it came from.
func drop_spell(spell: SpellData, area: Area, source: Area) -> void:
	if area == Area.LOOT:
		pending_loot.append(spell)
	elif area == Area.BACKPACK and backpack_has_room():
		backpack.append(spell)
	elif source == Area.LOOT:
		pending_loot.append(spell)
	else:
		backpack.append(spell)


static func fits_slot(slot: SpellSlotData, spell: SpellData) -> bool:
	return slot.is_tip == spell.tags.has("tip")


# Places spell into a slot of the wand equipped by mage_index (caller checks
# fits_slot). Returns the fusion result for body slots, or null.
func place_in_slot(mage_index: int, slot: SpellSlotData, spell: SpellData) -> AlchemyResult:
	var displaced: SpellData = slot.spell
	slot.spell = spell
	if displaced != null:
		stash_spell(displaced)
	if slot.is_tip:
		return null
	return try_fuse_wand(mage_index)


func stash_spell(spell: SpellData) -> void:
	if backpack_has_room():
		backpack.append(spell)
	else:
		pending_loot.append(spell)


func try_fuse_wand(mage_index: int) -> AlchemyResult:
	var wand: WandData = wands[mage_index] if mage_index < wands.size() else null
	if wand == null:
		return null
	var result := AlchemyFuser.try_fuse(wand)
	if result != null:
		apply_fusion_cost(mages[mage_index], result)
	return result


static func apply_fusion_cost(mage: MageData, result: AlchemyResult) -> void:
	match result.outcome:
		AlchemyResult.Outcome.FIZZLE:
			mage.mana_debt = mage.mana_allowance
		AlchemyResult.Outcome.BACKFIRE:
			mage.hp_penalty = backfire_penalty(mage)


static func backfire_penalty(mage: MageData) -> int:
	return mage.max_hp / 2


# --- wands ---

# Equips wand on mage_index; returns the previously equipped wand (now back in loot), or null.
func equip_wand(mage_index: int, wand: WandData) -> WandData:
	while wands.size() <= mage_index:
		wands.append(null)
	var old_wand: WandData = wands[mage_index]
	wands[mage_index] = wand
	if old_wand != null:
		pending_loot_wands.append(old_wand)
	return old_wand


func return_loot_wand(wand: WandData) -> void:
	pending_loot_wands.append(wand)


func equipped_wand(mage_index: int) -> WandData:
	return wands[mage_index] if mage_index < wands.size() else null


# Hands out loot wands in order to mages in order, while any are left.
func auto_assign() -> void:
	for i in mages.size():
		if pending_loot_wands.is_empty():
			break
		equip_wand(i, take_loot_wand(0))


# --- leaving the screen ---

func can_continue() -> bool:
	if not is_initial_setup:
		return true
	for i in mages.size():
		if equipped_wand(i) == null:
			return false
	return true


func finish() -> void:
	pending_loot.clear()
	battle_drops.clear()
	pending_loot_wands.clear()
	_run.is_initial_setup = false
