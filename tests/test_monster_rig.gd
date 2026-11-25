extends GutTest

const SAMPLE := """{"id": "imp", "scale": 0.5, "canvas": [256, 512], "cells": [1, 2],
 "joints": [{"name": "torso", "pivot": [100, 200], "parent": ""},
            {"name": "head", "pivot": [110, 120], "parent": "torso"}],
 "layers": [{"file": "rim_head.png", "joint": "head", "z": 0, "pos": [90, 80]},
            {"file": "head.png", "joint": "head", "z": 1000, "pos": [92, 82]}]}"""


func test_parses_canvas_and_cells() -> void:
	var rig := MonsterRig.from_json(SAMPLE)
	assert_eq(rig.id, "imp")
	assert_eq(rig.canvas_size, Vector2(256, 512))
	assert_eq(rig.cells, Vector2i(1, 2))


func test_parses_joint_hierarchy() -> void:
	var rig := MonsterRig.from_json(SAMPLE)
	assert_eq(rig.joints.size(), 2)
	assert_eq(rig.joint("head").parent, "torso")
	assert_eq(rig.joint("head").pivot, Vector2(110, 120))


func test_parses_layers_with_draw_order() -> void:
	var rig := MonsterRig.from_json(SAMPLE)
	assert_eq(rig.layers[0].z, 0)
	assert_eq(rig.layers[1].pos, Vector2(92, 82))
	assert_eq(rig.texture_path(rig.layers[1]), "res://assets/monsters/imp/head.png")


func test_invalid_json_gives_null() -> void:
	assert_null(MonsterRig.from_json("not json"))


func test_exported_goblin_rig_loads() -> void:
	var rig := MonsterRig.load_for("goblin")
	assert_not_null(rig)
	assert_eq(rig.cells, Vector2i(1, 1))
	assert_eq(rig.joint("ear_far").parent, "head")


func test_art_id_is_the_monster_script_name() -> void:
	assert_eq(MonsterRig.art_id_for(Goblin.new()), "goblin")
	assert_eq(MonsterRig.art_id_for(CaveSpider.new()), "cave_spider")


func test_every_game_monster_with_art_has_a_rig_parent_before_child() -> void:
	var rig := MonsterRig.load_for("cursed_knight")
	var seen := {}
	for j in rig.joints:
		assert_true(j.parent == "" or seen.has(j.parent), "%s before parent %s" % [j.name, j.parent])
		seen[j.name] = true
