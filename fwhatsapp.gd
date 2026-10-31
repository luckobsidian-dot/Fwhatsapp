extends Control
## Fwhatsapp – chat ve stylu WhatsApp (dark theme), Godot 4.x
## Tajné tlačítko = neviditelná plocha vpravo nahoře (přes ikonu ⋮).

const SAVE_PATH := "user://fake_chat.json"

const C_BG := Color("0b141a")
const C_HEADER := Color("202c33")
const C_IN := Color("202c33")
const C_OUT := Color("005c4b")
const C_TEXT := Color("e9edef")
const C_SUB := Color("8696a0")
const C_FIELD := Color("2a3942")
const C_GREEN := Color("00a884")

var contact_name := "Máma"
var contact_status := "online"
var avatar_color := Color("6b7c85")
var messages: Array = []

var msg_list: VBoxContainer
var scroll: ScrollContainer
var name_label: Label
var status_label: Label
var avatar: Avatar
var input: LineEdit
var editor: Control

var f_name: LineEdit
var f_status: LineEdit
var f_text: LineEdit
var f_time: LineEdit
var f_dir: OptionButton
var f_state: OptionButton
var f_color: ColorPickerButton


# ───────────── malé kreslicí třídy ─────────────

class Ticks extends Control:
	var state := 2 # 0 odesláno, 1 doručeno, 2 přečteno
	func _init(s: int = 2) -> void:
		state = s
		custom_minimum_size = Vector2(18, 14)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var col := Color("53bdeb") if state == 2 else Color("8696a0")
		if state >= 1:
			draw_polyline(PackedVector2Array([Vector2(0, 8), Vector2(4, 12), Vector2(12, 3)]), col, 1.6, true)
		draw_polyline(PackedVector2Array([Vector2(4, 8), Vector2(8, 12), Vector2(16, 3)]), col, 1.6, true)


class Avatar extends Control:
	var col := Color("6b7c85")
	var letter := "M"
	func _init() -> void:
		custom_minimum_size = Vector2(40, 40)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func set_info(c: Color, name_text: String) -> void:
		col = c
		letter = name_text.substr(0, 1).to_upper() if name_text != "" else "?"
		queue_redraw()
	func _draw() -> void:
		var c := size / 2.0
		draw_circle(c, minf(size.x, size.y) / 2.0, col)
		var f := ThemeDB.fallback_font
		var fs := 20
		var w := f.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		draw_string(f, Vector2(c.x - w.x / 2.0, c.y + fs * 0.35), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)


class HeaderIcons extends Control:
	func _init() -> void:
		custom_minimum_size = Vector2(80, 40)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var col := Color("aebac1")
		draw_rect(Rect2(8, 13, 16, 14), col, false, 2.0)
		draw_colored_polygon(PackedVector2Array([Vector2(25, 18), Vector2(33, 13), Vector2(33, 27), Vector2(25, 22)]), col)
		for i in 3:
			draw_circle(Vector2(62, 12 + i * 8), 2.2, col)


class SendIcon extends Control:
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_preset(Control.PRESET_FULL_RECT)
	func _draw() -> void:
		var c := size / 2.0
		draw_colored_polygon(PackedVector2Array([
			c + Vector2(-9, -10), c + Vector2(11, 0), c + Vector2(-9, 10), c + Vector2(-5, 0)
		]), Color.WHITE)


# ───────────── start ─────────────

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_build_editor()
	if not _load():
		_demo()
	_refresh_header()
	_rebuild()


func _demo() -> void:
	messages = [
		{"text": "Ahoj, už jsi doma?", "time": "20:41", "out": false, "state": 0},
		{"text": "Jo, před chvílí jsem dorazil", "time": "20:43", "out": true, "state": 2},
		{"text": "Fajn, tak ať se ti dobře spí", "time": "20:44", "out": false, "state": 0},
		{"text": "Díky, dobrou noc!", "time": "20:45", "out": true, "state": 2},
	]


# ───────────── UI ─────────────

func _flat(col: Color, radius: int, ml := 0, mt := 0, mr := 0, mb := 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = ml
	sb.content_margin_top = mt
	sb.content_margin_right = mr
	sb.content_margin_bottom = mb
	return sb


func _label(t: String, size_px: int, col: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_color", col)
	return l


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)

	# hlavička
	var header := PanelContainer.new()
	header.add_theme_stylebox_override("panel", _flat(C_HEADER, 0, 10, 30, 10, 8))
	root.add_child(header)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	header.add_child(hb)
	var back := _label("←", 26, C_TEXT)
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(back)
	avatar = Avatar.new()
	hb.add_child(avatar)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	vb.add_theme_constant_override("separation", -2)
	hb.add_child(vb)
	name_label = _label("", 18, C_TEXT)
	status_label = _label("", 13, C_SUB)
	vb.add_child(name_label)
	vb.add_child(status_label)
	hb.add_child(HeaderIcons.new())

	# zprávy
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	msg_list = VBoxContainer.new()
	msg_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	msg_list.add_theme_constant_override("separation", 3)
	scroll.add_child(msg_list)

	# vstupní lišta
	var bar := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		bar.add_theme_constant_override("margin_" + s, 6)
	root.add_child(bar)
	var ib := HBoxContainer.new()
	ib.add_theme_constant_override("separation", 6)
	bar.add_child(ib)
	var field := PanelContainer.new()
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.add_theme_stylebox_override("panel", _flat(C_FIELD, 24, 14, 4, 14, 4))
	ib.add_child(field)
	input = LineEdit.new()
	input.placeholder_text = "Napsat zprávu"
	input.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	input.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	input.add_theme_color_override("font_color", C_TEXT)
	input.add_theme_color_override("font_placeholder_color", C_SUB)
	input.add_theme_font_size_override("font_size", 17)
	input.text_submitted.connect(_send)
	field.add_child(input)
	var send := Button.new()
	send.custom_minimum_size = Vector2(48, 48)
	send.focus_mode = Control.FOCUS_NONE
	for s in ["normal", "hover", "pressed", "focus"]:
		send.add_theme_stylebox_override(s, _flat(C_GREEN, 24))
	send.add_child(SendIcon.new())
	send.pressed.connect(_send)
	ib.add_child(send)

	# TAJNÉ TLAČÍTKO – neviditelné, vpravo nahoře
	var secret := Button.new()
	secret.flat = true
	secret.focus_mode = Control.FOCUS_NONE
	for s in ["normal", "hover", "pressed", "focus"]:
		secret.add_theme_stylebox_override(s, StyleBoxEmpty.new())
	secret.anchor_left = 1.0
	secret.anchor_right = 1.0
	secret.anchor_top = 0.0
	secret.anchor_bottom = 0.0
	secret.offset_left = -80
	secret.offset_right = 0
	secret.offset_top = 0
	secret.offset_bottom = 75
	secret.pressed.connect(func(): editor.visible = true)
	add_child(secret)


func _build_editor() -> void:
	editor = ColorRect.new()
	(editor as ColorRect).color = Color(0, 0, 0, 0.7)
	editor.set_anchors_preset(Control.PRESET_FULL_RECT)
	editor.visible = false
	add_child(editor)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 50)
	margin.add_theme_constant_override("margin_bottom", 30)
	editor.add_child(margin)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _flat(C_HEADER, 16, 14, 14, 14, 14))
	margin.add_child(panel)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(sc)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 6)
	sc.add_child(vb)

	vb.add_child(_label("Editor chatu", 20, C_TEXT))

	f_name = LineEdit.new()
	f_name.text = contact_name
	f_name.text_changed.connect(func(t): contact_name = t; _refresh_header(); _save())
	_row(vb, "Jméno kontaktu", f_name)

	f_status = LineEdit.new()
	f_status.text = contact_status
	f_status.text_changed.connect(func(t): contact_status = t; _refresh_header(); _save())
	_row(vb, "Stav (online / píše… / naposledy online dnes v 21:14)", f_status)

	f_color = ColorPickerButton.new()
	f_color.color = avatar_color
	f_color.custom_minimum_size = Vector2(0, 36)
	f_color.color_changed.connect(func(c): avatar_color = c; _refresh_header(); _save())
	_row(vb, "Barva avataru", f_color)

	vb.add_child(HSeparator.new())

	f_text = LineEdit.new()
	f_text.placeholder_text = "Text zprávy"
	_row(vb, "Nová zpráva", f_text)

	f_time = LineEdit.new()
	f_time.text = _now()
	_row(vb, "Čas (HH:MM)", f_time)

	f_dir = OptionButton.new()
	f_dir.add_item("Příchozí (od kontaktu)")
	f_dir.add_item("Odchozí (moje)")
	_row(vb, "Směr", f_dir)

	f_state = OptionButton.new()
	f_state.add_item("Odesláno (1 šedá fajfka)")
	f_state.add_item("Doručeno (2 šedé)")
	f_state.add_item("Přečteno (2 modré)")
	f_state.select(2)
	_row(vb, "Stav odchozí zprávy", f_state)

	var add := Button.new()
	add.text = "Přidat zprávu"
	add.custom_minimum_size = Vector2(0, 44)
	add.pressed.connect(_on_add)
	vb.add_child(add)

	var del_last := Button.new()
	del_last.text = "Smazat poslední zprávu"
	del_last.pressed.connect(func():
		if messages.size() > 0:
			messages.pop_back()
			_save()
			_rebuild())
	vb.add_child(del_last)

	var clear := Button.new()
	clear.text = "Smazat všechny zprávy"
	clear.pressed.connect(func():
		messages.clear()
		_save()
		_rebuild())
	vb.add_child(clear)

	var close := Button.new()
	close.text = "Zavřít"
	close.custom_minimum_size = Vector2(0, 44)
	close.pressed.connect(func(): editor.visible = false)
	vb.add_child(close)


func _row(parent: Node, label_text: String, ctrl: Control) -> void:
	parent.add_child(_label(label_text, 13, C_SUB))
	parent.add_child(ctrl)


# ───────────── zprávy ─────────────

func _now() -> String:
	var t := Time.get_time_dict_from_system()
	return "%02d:%02d" % [t.hour, t.minute]


func _inc_time(s: String) -> String:
	var p := s.split(":")
	if p.size() != 2 or not p[0].is_valid_int() or not p[1].is_valid_int():
		return s
	var total := (int(p[0]) * 60 + int(p[1]) + 1) % 1440
	return "%02d:%02d" % [total / 60, total % 60]


func _on_add() -> void:
	var t := f_text.text.strip_edges()
	if t == "":
		return
	messages.append({"text": t, "time": f_time.text, "out": f_dir.selected == 1, "state": f_state.selected})
	f_text.text = ""
	f_time.text = _inc_time(f_time.text)
	_save()
	_rebuild()


func _send(_t: String = "") -> void:
	var t := input.text.strip_edges()
	if t == "":
		return
	input.text = ""
	var m := {"text": t, "time": _now(), "out": true, "state": 0}
	messages.append(m)
	_rebuild()
	get_tree().create_timer(0.8).timeout.connect(func(): m["state"] = 1; _rebuild())
	get_tree().create_timer(2.0).timeout.connect(func(): m["state"] = 2; _rebuild(); _save())
	_save()


func _refresh_header() -> void:
	name_label.text = contact_name
	status_label.text = contact_status
	status_label.visible = contact_status != ""
	avatar.set_info(avatar_color, contact_name)


func _rebuild() -> void:
	for c in msg_list.get_children():
		msg_list.remove_child(c)
		c.queue_free()
	msg_list.add_child(_date_chip("DNES"))
	for m in messages:
		msg_list.add_child(_make_bubble(m))
	await get_tree().process_frame
	await get_tree().process_frame
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)


func _date_chip(t: String) -> Control:
	var cc := CenterContainer.new()
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", _flat(Color("182229"), 8, 10, 4, 10, 4))
	pc.add_child(_label(t, 12, C_SUB))
	cc.add_child(pc)
	return cc


func _make_bubble(m: Dictionary) -> Control:
	var out: bool = m["out"]
	var txt: String = m["text"]
	var time_txt: String = m["time"]

	var outer := MarginContainer.new()
	outer.add_theme_constant_override("margin_left", 8)
	outer.add_theme_constant_override("margin_right", 8)
	var row := HBoxContainer.new()
	outer.add_child(row)

	var pc := PanelContainer.new()
	pc.size_flags_horizontal = Control.SIZE_EXPAND | (Control.SIZE_SHRINK_END if out else Control.SIZE_SHRINK_BEGIN)
	var sb := _flat(C_OUT if out else C_IN, 10, 9, 5, 9, 4)
	if out:
		sb.corner_radius_top_right = 2
	else:
		sb.corner_radius_top_left = 2
	pc.add_theme_stylebox_override("panel", sb)
	row.add_child(pc)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", -2)
	pc.add_child(vb)

	var fs := 16
	var font := ThemeDB.fallback_font
	var max_w := get_viewport_rect().size.x * 0.76 - 18.0
	var ts := font.get_multiline_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, max_w, fs)
	var tw := font.get_string_size(time_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + (24.0 if out else 0.0) + 6.0

	var lbl := _label(txt, fs, C_TEXT)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.custom_minimum_size.x = clampf(maxf(ts.x + 2.0, tw), 10.0, max_w)
	vb.add_child(lbl)

	var meta := HBoxContainer.new()
	meta.size_flags_horizontal = Control.SIZE_SHRINK_END
	meta.add_theme_constant_override("separation", 4)
	meta.add_child(_label(time_txt, 12, C_SUB))
	if out:
		var tk := Ticks.new(int(m["state"]))
		tk.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		meta.add_child(tk)
	vb.add_child(meta)
	return outer


# ───────────── ukládání ─────────────

func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({
		"name": contact_name,
		"status": contact_status,
		"color": avatar_color.to_html(),
		"messages": messages,
	}))


func _load() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var d = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(d) != TYPE_DICTIONARY:
		return false
	contact_name = d.get("name", contact_name)
	contact_status = d.get("status", contact_status)
	avatar_color = Color(d.get("color", avatar_color.to_html()))
	messages = d.get("messages", [])
	f_name.text = contact_name
	f_status.text = contact_status
	f_color.color = avatar_color
	return true
