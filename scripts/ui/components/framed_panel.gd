class_name FramedPanel
extends PanelContainer
## Theme panel plus the inset inner frame of the Ember drafts; `selected` swaps to the accent border.

@export var selected := false:
	set(v):
		selected = v
		queue_redraw()


func _draw() -> void:
	if selected:
		EmberDraw.rounded_rect(self, Rect2(Vector2.ZERO, size), Color.TRANSPARENT, Palette.COLOR_ACCENT, 2, 4)
	EmberDraw.inner_frame(self, Rect2(Vector2.ZERO, size))
