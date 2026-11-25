class_name SpellSlot
extends Control
## A spell socket as a Control: ring, rune and cost pips. Emits hover signals for tooltips.

signal spell_hovered(spell: SpellData, rect: Rect2)
signal spell_unhovered

@export var radius := 20.0:
	set(v):
		radius = v
		custom_minimum_size = Vector2(radius * 2.0 + 8.0, radius * 2.0 + 16.0)
var spell: SpellData = null:
	set(v):
		spell = v
		queue_redraw()
var charged := 0
var is_tip := false
var highlighted := false


func _ready() -> void:
	custom_minimum_size = Vector2(radius * 2.0 + 8.0, radius * 2.0 + 16.0)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(func() -> void: spell_unhovered.emit())


func _on_mouse_entered() -> void:
	if spell != null:
		spell_hovered.emit(spell, get_global_rect())


func _draw() -> void:
	var c := Vector2(size.x / 2.0, radius + 4.0)
	if spell == null:
		EmberDraw.empty_socket(self, c, radius, is_tip)
	else:
		EmberDraw.spell_socket(self, spell, c, radius, charged, is_tip, highlighted)
