## UIKit — the Sunless Crown look shared by every screen: the palette, the
## three fonts and the small set of building blocks the UI is made of.
## All sizes are in game pixels (the 640×360 base resolution).
class_name UIKit
extends RefCounted

# --- palette (tools/art/art.py) ---
const VOID := Color("060609")
const SOOT := Color("0e0f15")
const SLATE_1 := Color("171923")
const SLATE_2 := Color("222534")
const SLATE_3 := Color("303347")
const SLATE_4 := Color("454860")
const ASH := Color("646781")
const ASH_LT := Color("8f90a6")
const BONE := Color("c9c4b5")
const PARCH := Color("efe8d6")
const EMBER_DK := Color("6e2412")
const EMBER := Color("b8461b")
const FLAME := Color("ec7a2a")
const GOLD := Color("f5b84a")
const GOLD_LT := Color("ffe39a")
const BLOOD_DK := Color("5c1424")
const BLOOD := Color("c33a4b")
const ROSE := Color("f07a86")
const BRONZE := Color("9c6a3e")
const LILAC := Color("b79cf2")

const FONT_BODY: FontFile = preload("res://assets/fonts/PixelifySans-Variable.ttf")
const FONT_NUM: FontFile = preload("res://assets/fonts/Jersey10-Regular.ttf")
const FONT_TITLE: FontFile = preload("res://assets/fonts/Jacquard24-Regular.ttf")
const EMBER_ICON: Texture2D = preload("res://assets/ui/ember.png")
const SOUL_ICON: Texture2D = preload("res://assets/ui/soul.png")
const MARK: Texture2D = preload("res://assets/ui/mark32.png")

## Boon glyph per UpgradeData.UpgradeType.
const GLYPHS: Array[Texture2D] = [
	preload("res://assets/sprites/glyphs/blade.png"),
	preload("res://assets/sprites/glyphs/glass.png"),
	preload("res://assets/sprites/glyphs/heart.png"),
	preload("res://assets/sprites/glyphs/wing.png"),
	preload("res://assets/sprites/glyphs/twin.png"),
	preload("res://assets/sprites/glyphs/shield.png"),
	preload("res://assets/sprites/glyphs/lifesteal.png"),
	preload("res://assets/sprites/glyphs/dash.png"),
	preload("res://assets/sprites/glyphs/heart.png"),
	preload("res://assets/sprites/glyphs/wing.png"),
]

static var _medium: FontVariation


static func font_medium() -> Font:
	if _medium == null:
		_medium = FontVariation.new()
		_medium.base_font = FONT_BODY
		var tag := TextServerManager.get_primary_interface().name_to_tag("wght")
		_medium.variation_opentype = {tag: 560}
	return _medium


# --- rarity: metals for boons, metals + arcane + ember for items ---

static func boon_color(rarity: int) -> Color:
	return [ASH_LT, BRONZE, GOLD][clampi(rarity, 0, 2)]


static func boon_rarity_name(rarity: int) -> String:
	return TranslationServer.translate(["RARITY_COMMON", "RARITY_UNCOMMON", "RARITY_RARE"][clampi(rarity, 0, 2)])


static func item_color(rarity: int) -> Color:
	return [ASH_LT, BRONZE, GOLD, LILAC, FLAME][clampi(rarity, 0, 4)]


static func glyph_for(upgrade: UpgradeData) -> Texture2D:
	if upgrade.icon != null:
		return upgrade.icon
	return GLYPHS[clampi(upgrade.upgrade_type, 0, GLYPHS.size() - 1)]


# --- text ---

static func label(text: String, size: int = 10, color: Color = PARCH, font: Font = null) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font if font != null else FONT_BODY)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func num(text: String, size: int = 12, color: Color = PARCH) -> Label:
	return label(text, size, color, FONT_NUM)


static func title(text: String, size: int = 40, color: Color = GOLD_LT) -> Label:
	var l := label(text, size, color, FONT_TITLE)
	l.add_theme_color_override("font_shadow_color", EMBER_DK)
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", 2)
	return l


## A one-pixel dark drop shadow so text reads over the lit floor.
static func shadowed(l: Label) -> Label:
	l.add_theme_color_override("font_shadow_color", VOID)
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	return l


# --- frames ---

static func frame(bg: Color = SOOT, border: Color = SLATE_3, width: int = 1, pad: int = 8) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.set_content_margin_all(pad)
	s.anti_aliasing = false
	return s


static func panel(pad: int = 10, border: Color = SLATE_3, bg: Color = Color(SOOT, 0.97)) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", frame(bg, border, 1, pad))
	return p


static func icon(tex: Texture2D, scale: int = 1) -> TextureRect:
	var t := TextureRect.new()
	t.texture = tex
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if tex != null:
		t.custom_minimum_size = tex.get_size() * scale
	return t


static func key_cap(text: String, active: bool = false) -> PanelContainer:
	var p := PanelContainer.new()
	var s := frame(Color(0, 0, 0, 0), GOLD if active else SLATE_3, 1, 0)
	s.content_margin_left = 3
	s.content_margin_right = 3
	p.add_theme_stylebox_override("panel", s)
	p.add_child(num(text, 11, PARCH if active else ASH_LT))
	return p


# --- buttons ---

## Text-only menu entry: ash at rest, pale gold when focused or hovered.
static func menu_button(text: String, size: int = 14) -> Button:
	var b := Button.new()
	b.text = text
	b.flat = true
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_override("font", FONT_BODY)
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", ASH_LT)
	b.add_theme_color_override("font_hover_color", GOLD_LT)
	b.add_theme_color_override("font_focus_color", GOLD_LT)
	b.add_theme_color_override("font_pressed_color", GOLD)
	b.add_theme_color_override("font_hover_pressed_color", GOLD)
	b.add_theme_color_override("font_shadow_color", VOID)
	b.add_theme_constant_override("shadow_offset_x", 1)
	b.add_theme_constant_override("shadow_offset_y", 1)
	var empty := StyleBoxEmpty.new()
	empty.set_content_margin_all(2)
	for st in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		b.add_theme_stylebox_override(st, empty)
	b.mouse_entered.connect(b.grab_focus)
	return b


## Framed iron button for dialogs and panels.
static func button(text: String, size: int = 10) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_override("font", font_medium())
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", BONE)
	b.add_theme_color_override("font_hover_color", PARCH)
	b.add_theme_color_override("font_focus_color", PARCH)
	b.add_theme_color_override("font_pressed_color", GOLD_LT)
	b.add_theme_color_override("font_disabled_color", ASH)
	var normal := frame(SOOT, SLATE_3, 1, 0)
	normal.content_margin_left = 8
	normal.content_margin_right = 8
	normal.content_margin_top = 3
	normal.content_margin_bottom = 3
	var hot := normal.duplicate()
	hot.border_color = GOLD
	hot.bg_color = SLATE_1
	var dis := normal.duplicate()
	dis.border_color = SLATE_2
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hot)
	b.add_theme_stylebox_override("focus", hot)
	b.add_theme_stylebox_override("pressed", hot)
	b.add_theme_stylebox_override("hover_pressed", hot)
	b.add_theme_stylebox_override("disabled", dis)
	b.mouse_entered.connect(func() -> void:
		if not b.disabled:
			b.grab_focus())
	return b


## Dims everything below an overlay.
static func scrim(alpha: float = 0.72) -> ColorRect:
	var c := ColorRect.new()
	c.color = Color(VOID, alpha)
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	return c


static func hbox(sep: int = 6) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h


static func vbox(sep: int = 6) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v
