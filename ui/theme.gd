# theme.gd - Central UI theme definitions
extends Node

# Base colors for the collapsing world aesthetic
const PRIMARY_COLOR = Color(0.12, 0.12, 0.12) # Dark base background
const ACCENT_COLOR = Color(1.0, 0.47, 0.0) # Neon orange accent
const SECONDARY_COLOR = Color(0.39, 0.47, 0.51) # muted teal for secondary UI

# Gradient colors for background overlays
const GRADIENT_TOP = Color(0.08, 0.08, 0.16)
const GRADIENT_BOTTOM = Color(0.04, 0.02, 0.12)

# Font configuration
const DEFAULT_FONT = preload("res://PressStart2P.ttf")

func apply_theme(node: Control) -> void:
	"""Apply the defined theme to a Control node and its children.
	This is a helper to keep UI consistent.
	"""
	var style = StyleBoxFlat.new()
	style.bg_color = PRIMARY_COLOR
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = ACCENT_COLOR
	node.add_theme_stylebox_override("panel", style)
	node.add_theme_font_override("font", DEFAULT_FONT)
	node.add_theme_color_override("font_color", Color.WHITE)
