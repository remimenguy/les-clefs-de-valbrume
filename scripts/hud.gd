extends CanvasLayer

signal start_requested
signal new_campaign_requested
signal journal_requested
signal quit_requested
signal choice_requested(choice_id: String)
signal dialogue_dismissed
signal quality_changed(detailed: bool)

enum Screen { TITLE, GAMEPLAY, LEGACY_JOURNAL, CAMPAIGN_JOURNAL, DIALOGUE, SETTINGS }

const Progress = preload("res://scripts/progression.gd")
const MapDisplay = preload("res://scripts/map.gd")
const AccessSettings = preload("res://scripts/accessibility_settings.gd")
const CREST := preload("res://assets/icon.svg")
const TITLE_VIEW := preload("res://assets/title_view.webp")
const SURFACE := Color("#171d1bef")
const INK := Color("#1b211d")
const PALE := Color("#f7f3e9")
const MUTED := Color("#bbbfb5")
const GOLD := Color("#ecd2a1")
const EDGE := Color("#8a8d7a49")
const SPACING := 12

var root := Control.new()
var overlay := Control.new()
var hud := Control.new()
var rank: Label
var progress_text: Label
var progress_bar: ProgressBar
var objective: Label
var hint: Label
var distance_text: Label
var location_text: Label
var prompt_panel: PanelContainer
var prompt_text: Label
var toast_panel: PanelContainer
var toast_title: Label
var toast_text: Label
var toast_tween: Tween
var minimap: MapDisplay
var serif := SystemFont.new()
var quality_enabled := false
var guidance_enabled := true
var settings_path := AccessSettings.PATH

var _settings := AccessSettings.new()
var _screen := Screen.TITLE
var _settings_origin := Screen.TITLE
var _loading_label: Label
var _loading_bar: ProgressBar
var _title_has_save := false
var _journal_view: Dictionary = {}
var _choice_sent := false
var _dialogue_closed := false
var _capture_action := &""
var _interact_key_label: Label
var _journal_key_label: Label
var _settings_feedback: Label
var _rebind_interact: Button
var _rebind_journal: Button
var _world_time: Label
var _world_stock: Label
var _carried: Label


func _ready() -> void:
	serif.font_names = PackedStringArray(["Georgia", "Times New Roman", "DejaVu Serif"])
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fill(hud, root)
	_fill(overlay, root)
	_build_rank()
	_build_objective()
	_build_controls()
	_build_feedback()
	_settings.load_from(settings_path)
	_apply_accessibility()


func _build_rank() -> void:
	var card := _card(hud, Control.PRESET_TOP_LEFT, Vector4(32, 32, 316, 193), 20)
	var column := _column(card, 8)
	_brand(column, "Maison de Valbrume")
	rank = _label("", 30, PALE, true)
	column.add_child(rank)
	progress_bar = _progress_bar()
	column.add_child(progress_bar)
	progress_text = _label("", 15, MUTED)
	column.add_child(progress_text)
	_world_time = _label("", 14, GOLD, false, true)
	_world_stock = _label("", 14, MUTED, false, true)
	for line in [_world_time, _world_stock]:
		column.add_child(line)
		line.hide()


func _build_objective() -> void:
	var card := _card(hud, Control.PRESET_TOP_RIGHT, Vector4(-394, 32, -32, 224), 22)
	var column := _column(card, 10)
	column.add_child(_label("Objectif en cours", 14, GOLD))
	objective = _label("", 25, PALE, false, true)
	column.add_child(objective)
	hint = _label("", 16, MUTED, false, true)
	hint.add_theme_constant_override("line_spacing", 4)
	column.add_child(hint)
	var pill := _pill(column, "", GOLD)
	distance_text = pill


func _build_controls() -> void:
	var card := _card(hud, Control.PRESET_BOTTOM_LEFT, Vector4(32, -130, 550, -32), 14)
	var column := _column(card, 8)
	location_text = _label("", 15, PALE)
	column.add_child(location_text)
	_carried = _label("", 13, GOLD, false, true)
	column.add_child(_carried)
	_carried.hide()
	var legend := _row(column, 14)
	_legend_item(legend, "zqsd / wasd", "Déplacer")
	_legend_item(legend, "maj", "Courir")
	_legend_item(legend, "clic droit", "Caméra")
	_journal_key_label = _legend_item(legend, "j", "Journal")
	minimap = MapDisplay.new()
	_attach(hud, minimap, Control.PRESET_BOTTOM_RIGHT, Vector4(-220, -220, -32, -32))
	minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _build_feedback() -> void:
	prompt_panel = _card(hud, Control.PRESET_CENTER_BOTTOM, Vector4(-177, -112, 177, -52), 10)
	prompt_panel.add_theme_stylebox_override("panel", _style(SURFACE, Color("#ecd2a17a"), 10))
	var row := _row(prompt_panel, 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_interact_key_label = _pill(row, "e", GOLD)
	prompt_text = _label("", 18, PALE, false, true)
	prompt_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(prompt_text)
	prompt_panel.hide()

	toast_panel = _card(hud, Control.PRESET_CENTER_TOP, Vector4(-224, 32, 224, 124), 18)
	var toast := _column(toast_panel, 5)
	toast_title = _label("", 20, GOLD, false, true)
	toast_text = _label("", 15, PALE, false, true)
	toast.add_child(toast_title)
	toast.add_child(toast_text)
	toast_panel.hide()


func title_screen(has_save: bool) -> void:
	_screen = Screen.TITLE
	_title_has_save = has_save
	hud.hide()
	_clear_overlay()
	_backdrop(true)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	_attach(overlay, content, Control.PRESET_CENTER_LEFT, Vector4(88, -250, 635, 290))
	_brand(content, "Une aventure médiévale")
	var title := _label("Les Clefs de\nValbrume", 86, PALE, true)
	title.add_theme_constant_override("line_spacing", -12)
	content.add_child(title)
	var copy := _label("Des écuries au trône, gagne la confiance de la cour et ouvre les portes de la vallée.", 21, PALE, false, true)
	copy.add_theme_constant_override("line_spacing", 5)
	content.add_child(copy)
	_gap(content, 7)
	var start := _button("Reprendre le service  →" if has_save else "Entrer au service  →")
	var actions := _row(content)
	actions.add_child(start)
	start.pressed.connect(func() -> void: start_requested.emit())
	_add_options(actions)
	if has_save:
		var fresh := _button("Nouvelle partie", true)
		content.add_child(fresh)
		fresh.pressed.connect(_confirm_new_campaign)
	start.grab_focus()
	content.add_child(_label("Partie solo · Sauvegarde automatique", 15, MUTED))


func update_status(progress: Progress, next_action: String, next_hint: String) -> void:
	rank.text = progress.rank_title()
	_show_progress(progress, progress_bar, progress_text)
	objective.text = next_action
	hint.text = next_hint


func update_context(player: Vector3, target: Vector3, has_target: bool, royal: bool, action: String) -> void:
	var show_target := has_target and guidance_enabled
	minimap.update_map(player, target, show_target, royal and player.z >= 22)
	var outside := player.z >= 22 or absf(player.x) > 22 or player.z < -22
	_set_text(location_text, "Vallée de Valbrume" if outside else "Château de Valbrume")
	prompt_panel.visible = not action.is_empty()
	_set_text(prompt_text, action)
	var meters := Vector2(player.x - target.x, player.z - target.z).length()
	distance_text.get_parent().visible = guidance_enabled
	_set_text(distance_text, "À %d m" % ceili(meters) if show_target else "Exploration libre")


func notify(title: String, description: String) -> void:
	if toast_tween and toast_tween.is_running():
		toast_tween.kill()
	toast_title.text = title
	toast_text.text = description
	toast_panel.modulate.a = 1.0
	toast_panel.show()
	toast_tween = create_tween()
	toast_tween.tween_interval(3.7)
	toast_tween.tween_property(toast_panel, "modulate:a", 0.0, 0.45)
	toast_tween.tween_callback(toast_panel.hide)


func gameplay() -> void:
	_screen = Screen.GAMEPLAY
	hud.show()
	_clear_overlay()
	overlay.hide()


func journal(progress: Progress) -> void:
	_screen = Screen.LEGACY_JOURNAL
	hud.hide()
	_clear_overlay()
	_backdrop(false)
	var half_height := 329.0 if progress.is_king() else 290.0
	var shell := _card(overlay, Control.PRESET_CENTER, Vector4(-447, -half_height, 447, half_height), 24)
	var layout := _row(shell, 28)
	var summary := _column(layout, 14)
	summary.custom_minimum_size.x = 269
	_brand(summary, "Maison de Valbrume")
	summary.add_child(_label("Journal de\nservice", 43, PALE, true))
	_gap(summary, 4)
	summary.add_child(_label("Ton rang", 15, MUTED))
	summary.add_child(_label(progress.rank_title(), 26, GOLD, false, true))
	var bar := _progress_bar()
	var count := _label("", 15, MUTED)
	summary.add_child(bar)
	summary.add_child(count)
	_show_progress(progress, bar, count)
	if not progress.is_king():
		summary.add_child(_label("La herse s’ouvrira après ton couronnement.", 15, MUTED, false, true))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	summary.add_child(spacer)
	var resume := _button("Reprendre le jeu  →")
	summary.add_child(resume)
	resume.pressed.connect(func() -> void: journal_requested.emit())
	var exit := _button("Quitter le jeu", true)
	summary.add_child(exit)
	exit.pressed.connect(func() -> void: quit_requested.emit())
	resume.focus_neighbor_bottom = resume.get_path_to(exit)
	exit.focus_neighbor_top = exit.get_path_to(resume)
	resume.grab_focus()

	var entries := _column(layout, 8)
	entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entries.add_child(_label("Services du château", 21, PALE))
	for i in Progress.DEEDS.size():
		var state := "Terminé" if i < progress.deed else ("En cours" if i == progress.deed else "À venir")
		_entry(entries, "%02d" % (i + 1), Progress.DEEDS[i]["title"], state)
	if progress.is_king():
		_gap(entries, 3)
		entries.add_child(_label("Lieux de la vallée", 19, PALE))
		for id: String in Progress.LANDMARKS:
			var state := "Découvert" if progress.discoveries.has(id) else "À découvrir"
			_entry(entries, "•", Progress.LANDMARKS[id], state)


func update_campaign(view: Dictionary) -> void:
	_set_text(rank, str(view.get("rank_title", "Domestique")))
	_show_campaign_progress(view, progress_bar, progress_text)
	_set_text(_world_time, _time_caption(view))
	_set_text(_world_stock, _stock_caption(int(view.get("grain", 0))))
	var cargo := str(view.get("carried", ""))
	_set_text(_carried, "Objet porté · " + cargo)
	_world_time.show()
	_world_stock.show()
	_carried.visible = not cargo.is_empty()


func campaign_journal(view: Dictionary) -> void:
	_screen = Screen.CAMPAIGN_JOURNAL
	_journal_view = view.duplicate(true)
	hud.hide()
	_clear_overlay()
	_backdrop(false)
	var shell := _card(overlay, Control.PRESET_CENTER, Vector4(-470, -320, 470, 320), 24)
	var layout := _row(shell, 30)
	var summary := _column(layout, 12)
	summary.custom_minimum_size.x = 266
	_brand(summary, "Maison de Valbrume")
	summary.add_child(_label("Journal de\nservice", 41, PALE, true))
	summary.add_child(_label(str(view.get("rank_title", "Domestique")), 23, GOLD, false, true))
	var bar := _progress_bar()
	var count := _label("", 14, MUTED, false, true)
	summary.add_child(bar)
	summary.add_child(count)
	_show_campaign_progress(view, bar, count)
	_gap(summary, 4)
	summary.add_child(_label(_time_caption(view), 15, GOLD))
	summary.add_child(_label(_stock_caption(int(view.get("grain", 0))), 15, MUTED))
	var supporters: Array = view.get("supporters", [])
	if not supporters.is_empty():
		_gap(summary, 6)
		summary.add_child(_label("Tes soutiens", 14, GOLD))
		summary.add_child(_label(", ".join(supporters), 15, PALE, false, true))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	summary.add_child(spacer)
	var resume := _button("Reprendre le jeu  →")
	summary.add_child(resume)
	resume.pressed.connect(func() -> void: journal_requested.emit())
	_add_options(summary)
	var exit := _button("Quitter le jeu", true)
	summary.add_child(exit)
	exit.pressed.connect(func() -> void: quit_requested.emit())

	var scroll := _scroll(layout)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var entries := _column(scroll, 10)
	entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entries.add_child(_label("Priorités", 24, PALE, true))
	var objectives: Array = view.get("objectives", [])
	if objectives.is_empty():
		entries.add_child(_label("Tu peux explorer à ton rythme.", 16, MUTED, false, true))
	for item: Dictionary in objectives:
		_journal_note(entries, str(item.get("title", "")), str(item.get("hint", "")), true)
	_gap(entries, 10)
	entries.add_child(_label("Faits consignés", 23, PALE, true))
	var records: Array = view.get("records", [])
	if records.is_empty():
		entries.add_child(_label("Les faits importants de ton service apparaîtront ici.", 16, MUTED, false, true))
	for index in range(records.size() - 1, -1, -1):
		_journal_note(entries, "", str(records[index]), false)
	resume.grab_focus()


func dialogue(scene: Dictionary) -> void:
	_screen = Screen.DIALOGUE
	_choice_sent = false
	_dialogue_closed = false
	hud.hide()
	_clear_overlay()
	_backdrop(false)
	var shell := _card(overlay, Control.PRESET_CENTER, Vector4(-390, -300, 390, 300), 28)
	var panel := _column(shell, 13)
	_brand(panel, str(scene.get("speaker", "Maison de Valbrume")))
	panel.add_child(_label(str(scene.get("title", "Conversation")), 34, PALE, true, true))
	var scroll := _scroll(panel)
	var content := _column(scroll, 13)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var speech_size := roundi(19.0 * _settings.text_scale / 100.0)
	var speech := _label(str(scene.get("text", "")), speech_size, PALE, false, true)
	speech.add_theme_constant_override("line_spacing", 5)
	content.add_child(speech)
	_gap(content, 3)
	var initial_focus: Button
	for item: Dictionary in scene.get("choices", []):
		var tile := _note_panel(content, Color("#292e27"))
		var option := _column(tile, 3)
		var choice := _button(str(item.get("label", "")), true)
		var id := str(item.get("id", ""))
		choice.name = "Choice_" + id
		choice.alignment = HORIZONTAL_ALIGNMENT_LEFT
		choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		choice.add_theme_font_size_override("font_size", maxi(17, speech_size - 1))
		option.add_child(choice)
		choice.pressed.connect(_select_choice.bind(id))
		var detail := str(item.get("detail", ""))
		if not detail.is_empty():
			var explanation := _label(detail, maxi(15, speech_size - 3), MUTED, false, true)
			explanation.add_theme_constant_override("line_spacing", 3)
			option.add_child(explanation)
		if initial_focus == null:
			initial_focus = choice
	var back := _button("Revenir", true)
	panel.add_child(back)
	back.pressed.connect(dismiss_dialogue)
	if initial_focus == null:
		initial_focus = back
	initial_focus.grab_focus()


func dismiss_dialogue() -> void:
	if _screen != Screen.DIALOGUE or _dialogue_closed:
		return
	_dialogue_closed = true
	dialogue_dismissed.emit()


func is_settings_open() -> bool:
	return _screen == Screen.SETTINGS


func _select_choice(id: String) -> void:
	if _screen != Screen.DIALOGUE or _choice_sent or _dialogue_closed or id.is_empty():
		return
	_choice_sent = true
	choice_requested.emit(id)


func _show_campaign_progress(view: Dictionary, bar: ProgressBar, count: Label) -> void:
	var completed := int(view.get("completed", 0))
	var total := int(view.get("total", 0))
	bar.max_value = maxi(1, total)
	bar.value = completed
	if bool(view.get("royal", false)):
		_set_text(count, "%d sur %d affaires instruites" % [completed, total])
	else:
		_set_text(count, "%d sur %d étapes de l’ascension" % [completed, total])


func _time_caption(view: Dictionary) -> String:
	var minute := clampi(int(view.get("minute", 0)), 0, 1439)
	return "Jour %d · %02d h %02d" % [int(view.get("day", 1)), floori(minute / 60.0), minute % 60]


func _stock_caption(grain: int) -> String:
	return "Réserve · %d %s de grain" % [grain, "mesure" if grain == 1 else "mesures"]


func _journal_note(parent: Control, title: String, message: String, priority: bool) -> void:
	var card := _note_panel(parent, Color("#2e342a") if priority else Color("#262b25"))
	var note := _column(card, 4)
	if not title.is_empty():
		note.add_child(_label(title, 17, GOLD if priority else PALE, false, true))
	if not message.is_empty():
		var detail := _label(message, 15, PALE if title.is_empty() else MUTED, false, true)
		detail.add_theme_constant_override("line_spacing", 3)
		note.add_child(detail)


func _note_panel(parent: Control, fill: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _style(fill, EDGE, 11, 8))
	parent.add_child(panel)
	return panel


func _scroll(parent: Control) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.focus_mode = Control.FOCUS_ALL
	scroll.gui_input.connect(_scroll_input.bind(scroll))
	parent.add_child(scroll)
	return scroll


func _scroll_input(event: InputEvent, scroll: ScrollContainer) -> void:
	if not event is InputEventKey or not event.pressed:
		return
	var stride := 34
	match event.keycode:
		KEY_UP:
			scroll.scroll_vertical -= stride
		KEY_DOWN:
			scroll.scroll_vertical += stride
		KEY_PAGEUP:
			scroll.scroll_vertical -= int(scroll.size.y * 0.8)
		KEY_PAGEDOWN:
			scroll.scroll_vertical += int(scroll.size.y * 0.8)
		_:
			return
	scroll.accept_event()


func _entry(parent: VBoxContainer, number: String, title: String, status: String) -> void:
	var box := PanelContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var active := status == "En cours"
	var fill := Color("#343a2c") if active else Color("#252b27")
	box.add_theme_stylebox_override("panel", _style(fill, Color("#818a7354") if active else Color.TRANSPARENT, 6, 7))
	parent.add_child(box)
	var row := _row(box, 10)
	var index := _label(number, 13, GOLD if active else MUTED)
	index.custom_minimum_size.x = 25
	row.add_child(index)
	var name := _label(title, 15, PALE)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name)
	row.add_child(_label(status, 13, GOLD if active else MUTED))


func _show_progress(progress: Progress, bar: ProgressBar, count: Label) -> void:
	var completed := progress.discoveries.size() if progress.is_king() else progress.deed
	var total := Progress.LANDMARKS.size() if progress.is_king() else Progress.DEEDS.size()
	bar.max_value = total
	bar.value = completed
	if progress.is_king():
		count.text = "%d sur %d lieux découverts" % [completed, total]
	else:
		count.text = "%d sur %d étapes de l’ascension" % [completed, total]


func _brand(parent: Control, caption: String) -> void:
	var row := _row(parent, 8)
	var icon := TextureRect.new()
	icon.texture = CREST
	icon.custom_minimum_size = Vector2(26, 26)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	row.add_child(_label(caption, 15, GOLD))


func _legend_item(parent: Control, key: String, caption: String) -> Label:
	var item := _row(parent, 6)
	var badge := _pill(item, key, PALE)
	item.add_child(_label(caption, 13, MUTED))
	return badge


func _pill(parent: Control, caption: String, color: Color) -> Label:
	var capsule := PanelContainer.new()
	capsule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capsule.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	capsule.add_theme_stylebox_override("panel", _style(Color("#30372f"), EDGE, 4, 7))
	parent.add_child(capsule)
	var label := _label(caption, 13, color)
	capsule.add_child(label)
	return label


func _progress_bar() -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size.y = 4
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("background", _style(Color("#3a4037"), Color.TRANSPARENT, 0, 3))
	bar.add_theme_stylebox_override("fill", _style(GOLD, Color.TRANSPARENT, 0, 3))
	return bar


func _clear_overlay() -> void:
	for child in overlay.get_children():
		overlay.remove_child(child)
		child.queue_free()
	overlay.show()


func _backdrop(cinematic: bool) -> void:
	if cinematic:
		var base := ColorRect.new()
		base.color = Color("#171e19")
		_fill(base, overlay)
		var view := TextureRect.new()
		view.texture = TITLE_VIEW
		view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		_fill(view, overlay)
		view.anchor_left = 0.37
	var background := TextureRect.new()
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.40, 0.76, 1.0])
	ramp.colors = PackedColorArray([Color("#101613fa"), Color("#101613c9"),
		Color("#10161337"), Color("#1016130b")]) if cinematic else PackedColorArray([
			Color("#101613c9"), Color("#101613c9"), Color("#101613c9"), Color("#101613c9")])
	var texture := GradientTexture2D.new()
	texture.gradient = ramp
	texture.width = 512
	texture.height = 64
	texture.fill_from = Vector2(0.0, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	background.texture = texture
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_fill(background, overlay)


func _fill(control: Control, parent: Control) -> void:
	parent.add_child(control)
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _attach(parent: Control, control: Control, preset: Control.LayoutPreset, offsets: Vector4) -> void:
	parent.add_child(control)
	control.set_anchors_and_offsets_preset(preset)
	control.offset_left = offsets.x
	control.offset_top = offsets.y
	control.offset_right = offsets.z
	control.offset_bottom = offsets.w


func _card(parent: Control, preset: Control.LayoutPreset, offsets: Vector4, margin: int) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := _style(SURFACE, EDGE, margin)
	style.shadow_color = Color("#080c0a49")
	style.shadow_size = 7
	style.shadow_offset = Vector2(0, 3)
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_attach(parent, panel, preset, offsets)
	return panel


func _style(fill: Color, border: Color, margin: int, radius: int = 13) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	if border.a > 0.0:
		style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_content_margin(side, margin)
	return style


func _label(value: String, font_size: int, color: Color, with_serif: bool = false, wrap: bool = false) -> Label:
	var line := Label.new()
	line.text = value
	line.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	line.add_theme_font_size_override("font_size", font_size)
	line.add_theme_color_override("font_color", color)
	if with_serif:
		line.add_theme_font_override("font", serif)
	if wrap:
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line


func _button(caption: String, secondary: bool = false) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(184, 47)
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 17)
	for key in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
		button.add_theme_color_override(key, PALE if secondary else INK)
	button.add_theme_stylebox_override("normal", _style(Color("#2b332d") if secondary else GOLD, EDGE, 10, 10))
	button.add_theme_stylebox_override("hover", _style(Color("#394238") if secondary else Color("#f7e4bb"), EDGE, 10, 10))
	button.add_theme_stylebox_override("pressed", _style(Color("#222823") if secondary else Color("#c3a671"), EDGE, 10, 10))
	var focus := _style(Color.TRANSPARENT, PALE, 0, 10)
	focus.set_border_width_all(2)
	button.add_theme_stylebox_override("focus", focus)
	return button


func _column(parent: Control, separation: int = SPACING) -> VBoxContainer:
	var node := VBoxContainer.new()
	node.add_theme_constant_override("separation", separation)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node


func _row(parent: Control, separation: int = SPACING) -> HBoxContainer:
	var node := HBoxContainer.new()
	node.add_theme_constant_override("separation", separation)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node


func _gap(parent: Control, height: int) -> void:
	var space := Control.new()
	space.custom_minimum_size.y = height
	space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(space)


func _set_text(label: Label, value: String) -> void:
	if label.text != value:
		label.text = value


func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var key: Key = event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode
	if _screen == Screen.SETTINGS:
		if key == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			if _capture_action.is_empty():
				_close_settings()
			else:
				_capture_action = &""
				_refresh_key_buttons()
				_settings_feedback.text = "Attribution annulée."
		elif not _capture_action.is_empty():
			get_viewport().set_input_as_handled()
			if event.ctrl_pressed or event.alt_pressed or event.meta_pressed or event.shift_pressed:
				_settings_feedback.text = "Appuie sur une touche seule."
				return
			var error := _settings.bind(_capture_action, key)
			if not error.is_empty():
				_settings_feedback.text = error
				return
			_capture_action = &""
			_apply_accessibility()
			_refresh_key_buttons()
			_save_options("La nouvelle touche est active.")
	elif _screen == Screen.DIALOGUE and key == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		dismiss_dialogue()


func _add_options(parent: Control) -> Button:
	var options := _button("Options", true)
	options.name = "Options"
	parent.add_child(options)
	options.pressed.connect(_open_settings)
	return options


func _open_settings() -> void:
	_settings_origin = _screen
	_capture_action = &""
	_settings_screen()


func _settings_screen() -> void:
	_screen = Screen.SETTINGS
	_clear_overlay()
	_backdrop(false)
	var card := _card(overlay, Control.PRESET_CENTER, Vector4(-335, -285, 335, 285), 26)
	var panel := _column(card, 13)
	_brand(panel, "Maison de Valbrume")
	panel.add_child(_label("Options", 35, PALE, true))
	var scroll := _scroll(panel)
	var options := _column(scroll, 11)
	options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	options.add_child(_label("Affichage", 19, GOLD))
	var detailed := CheckButton.new()
	detailed.text = "Activer le rendu détaillé"
	detailed.button_pressed = quality_enabled
	detailed.add_theme_font_size_override("font_size", 16)
	options.add_child(detailed)
	detailed.toggled.connect(_toggle_quality)
	options.add_child(_label("Le mode fluide réduit le coût du rendu 3D.", 14, MUTED, false, true))
	options.add_child(_label("Lecture et guidage", 19, GOLD))
	var guidance := CheckButton.new()
	guidance.name = "Guidance"
	guidance.text = "Afficher les repères et les distances"
	guidance.button_pressed = guidance_enabled
	guidance.add_theme_font_size_override("font_size", 16)
	options.add_child(guidance)
	guidance.toggled.connect(_toggle_guidance)

	var text_row := _row(options)
	var label := _label("Taille du texte des dialogues", 16, PALE)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_row.add_child(label)
	var scales := OptionButton.new()
	scales.name = "DialogueTextScale"
	scales.custom_minimum_size = Vector2(117, 34)
	scales.add_theme_font_size_override("font_size", 16)
	for size_percent: int in AccessSettings.TEXT_SCALES:
		scales.add_item("%d %%" % size_percent, size_percent)
		if size_percent == _settings.text_scale:
			scales.select(scales.item_count - 1)
	text_row.add_child(scales)
	scales.item_selected.connect(func(index: int) -> void: _change_scale(scales.get_item_id(index)))

	_gap(options, 4)
	options.add_child(_label("Commandes clavier", 19, GOLD))
	_rebind_interact = _setting_key(options, "Interagir", AccessSettings.INTERACT, "RebindInteract")
	_rebind_journal = _setting_key(options, "Journal", AccessSettings.JOURNAL, "RebindJournal")
	_refresh_key_buttons()
	_settings_feedback = _label("Échap permet toujours de revenir.", 14, MUTED, false, true)
	options.add_child(_settings_feedback)
	var footer := _row(panel)
	var back := _button("Revenir  →")
	back.name = "CloseOptions"
	footer.add_child(back)
	back.pressed.connect(_close_settings)
	var reset := _button("Rétablir les valeurs", true)
	reset.name = "ResetOptions"
	footer.add_child(reset)
	reset.pressed.connect(_reset_settings)
	guidance.grab_focus()


func _setting_key(parent: Control, caption: String, action: StringName, node_name: String) -> Button:
	var row := _row(parent)
	var label := _label(caption, 16, PALE)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var button := _button("", true)
	button.name = node_name
	button.custom_minimum_size = Vector2(172, 39)
	row.add_child(button)
	button.pressed.connect(_begin_rebind.bind(action))
	return button


func _begin_rebind(action: StringName) -> void:
	_capture_action = action
	_refresh_key_buttons()
	_settings_feedback.text = "Appuie sur la nouvelle touche. Échap annule."


func _refresh_key_buttons() -> void:
	var pairs := {
		AccessSettings.INTERACT: [_rebind_interact, _settings.interact_key],
		AccessSettings.JOURNAL: [_rebind_journal, _settings.journal_key],
	}
	for action: StringName in pairs:
		var button: Button = pairs[action][0]
		button.text = "En attente…" if _capture_action == action else AccessSettings.key_label(pairs[action][1])


func _toggle_guidance(enabled: bool) -> void:
	_settings.guidance = enabled
	_apply_accessibility()
	_save_options()


func _change_scale(size_percent: int) -> void:
	_settings.text_scale = size_percent
	_save_options("La taille sera utilisée au prochain dialogue.")


func _toggle_quality(enabled: bool) -> void:
	_settings.detailed_rendering = enabled
	_apply_accessibility()
	_save_options("Qualité d’affichage enregistrée.")


func _apply_accessibility() -> void:
	quality_enabled = _settings.detailed_rendering
	quality_changed.emit(quality_enabled)
	guidance_enabled = _settings.guidance
	_interact_key_label.text = AccessSettings.key_label(_settings.interact_key)
	_journal_key_label.text = AccessSettings.key_label(_settings.journal_key)


func _reset_settings() -> void:
	_capture_action = &""
	_settings.reset()
	_apply_accessibility()
	_settings_screen()
	_save_options("Les valeurs d’origine sont rétablies.")


func _save_options(success: String = "Option enregistrée.") -> void:
	_settings_feedback.text = success if _settings.save_to(settings_path) == OK 		else "Option active pour cette session. L’enregistrement a échoué."


func _close_settings() -> void:
	_capture_action = &""
	if _settings_origin == Screen.CAMPAIGN_JOURNAL:
		campaign_journal(_journal_view)
	else:
		title_screen(_title_has_save)


func _confirm_new_campaign() -> void:
	_clear_overlay()
	_backdrop(false)
	var shell := _card(overlay, Control.PRESET_CENTER, Vector4(-250, -113, 250, 113), 23)
	var stack := _column(shell, 14)
	stack.add_child(_label("Recommencer le service", 25, PALE))
	stack.add_child(_label("La sauvegarde actuelle est mise de côté avant de commencer une nouvelle partie.", 16, MUTED, false, true))
	var actions := _row(stack)
	var back := _button("Revenir au menu", true)
	var accept := _button("Commencer")
	actions.add_child(back)
	actions.add_child(accept)
	back.pressed.connect(func() -> void: title_screen(_title_has_save))
	accept.pressed.connect(func() -> void: new_campaign_requested.emit())
	back.grab_focus()


func loading_status(fraction: float) -> void:
	if fraction <= 0.0 and not is_instance_valid(_loading_bar):
		_clear_overlay()
		_backdrop(true)
		var shell := _card(overlay, Control.PRESET_CENTER, Vector4(-253, -78, 253, 78), 24)
		var stack := _column(shell, 14)
		stack.add_child(_label("La cour s’éveille", 26, PALE, true))
		_loading_label = _label("Préparation du château…", 16, MUTED)
		stack.add_child(_loading_label)
		_loading_bar = _progress_bar()
		stack.add_child(_loading_bar)
	if is_instance_valid(_loading_bar):
		_loading_bar.value = roundi(fraction * 100.0)
		if fraction >= 0.9:
			_loading_label.text = "Installation des derniers éléments…"


func loading_failed(message: String) -> void:
	_loading_bar = null
	_clear_overlay()
	_backdrop(false)
	var shell := _card(overlay, Control.PRESET_CENTER, Vector4(-250, -100, 250, 100), 24)
	var stack := _column(shell, 14)
	stack.add_child(_label("Chargement interrompu", 23, PALE))
	stack.add_child(_label(message, 16, MUTED, false, true))
	var back := _button("Retour au menu")
	stack.add_child(back)
	back.pressed.connect(func() -> void: title_screen(_title_has_save))
	back.grab_focus()
