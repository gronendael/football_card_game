extends RefCounted
class_name ToolsModalLayout

## Center a scroll-wrapped modal panel on the viewport (Tools hub / game Tools menu).


static func add_centered_scroll(margin_wrap: Control) -> ScrollContainer:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin_wrap.add_child(center)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(scroll)
	return scroll


static func clamp_scroll_to_viewport(scroll: ScrollContainer, panel: Control, edge_margin: float = 36.0) -> void:
	if scroll == null or panel == null:
		return
	var vp_h := scroll.get_viewport_rect().size.y
	var content_h := panel.get_combined_minimum_size().y
	var min_w := panel.custom_minimum_size.x
	if min_w <= 0.0:
		min_w = panel.get_combined_minimum_size().x
	scroll.custom_minimum_size = Vector2(min_w, minf(content_h, maxf(120.0, vp_h - edge_margin)))
