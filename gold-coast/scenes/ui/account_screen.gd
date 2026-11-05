class_name AccountScreen
extends Control
## The account card on the title screen, for living in the shared Gold Coast
## online (see Online):
## - Create account: your name; a username (her name in Gold Coast, which other
##   players see); a password (the eye shows it); an email (to log in, and
##   later to reset the password); your date of birth (18 or older); and a box
##   to tick: you're 18+ and agree to the Terms, Community Guidelines, Privacy
##   Policy, Disclaimer, and Child safety (each one opens to read: see Legal).
##   "Sign up · it's free" makes the account.
## - Log in: your email and password.
## - Play offline (under the sign): single player, saved in this browser.
## Mistakes show in red under each field, in plain words. It sends `done` once
## the player is logged in, or has chosen to play offline.

signal done

## Where the card is: on the right of the screen (the sign moves to the left).
const CARD := Rect2(652.0, 18.0, 460.0, 612.0)
## Where "Play offline" is: under the sign.
const OFFLINE_AT := Vector2(40.0, 452.0)
const MONTHS := ["January", "February", "March", "April", "May", "June", "July", "August", "September",
		"October", "November", "December"]
const SUBMIT := ["Sign up  ·  it's free", "Log in"]
const FOOTER := ["Your character lives in the same Gold Coast as everyone else who signs up.",
		"Welcome back! Your town is waiting."]

# The card's colors: a light, friendly sign-up page.
const WHITE := Color("ffffff")
const INK := Color("1f2937")
const LABEL := Color("374151")
const HINT := Color("5b6472")
const FIELD := Color("eef1f6")
const FOCUS := Color("8cc29f")
const PLACEHOLDER := Color("98a1ae")
const GREEN := Color("4f9a6c")
const GREEN_LIGHT := Color("5aa878")
const GREEN_DARK := Color("3b7a54")
const RED := Color("c0392b")
const LINK := Color("2563eb")
const SHADOW := Color(0.0, 0.0, 0.0, 0.18)

var _tabs: Array[Button] = []
var _forms: Array[VBoxContainer] = []
var _inputs := {} # each field's key -> its LineEdit
var _errors := {} # each field's key -> the red line under it
var _day: OptionButton
var _month: OptionButton
var _year: OptionButton
var _agree: TickBox
var _message: Label
var _submit: Button
var _footer: Label
var _document: PanelContainer
var _document_title: Label
var _document_text: RichTextLabel
var _busy := false


func _ready() -> void:
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = _make_theme()
	_build_card()
	_build_document()
	_build_offline_link()
	show_tab(0)


## Shows the card.
func open() -> void:
	visible = true
	close_document()
	_clear_errors()


func close() -> void:
	visible = false


func is_open() -> bool:
	return visible


## Shows a tab: 0 for Create account, 1 for Log in.
func show_tab(index: int) -> void:
	for i in _tabs.size():
		_tabs[i].set_pressed_no_signal(i == index)
		_forms[i].visible = i == index
	_submit.text = SUBMIT[index]
	_footer.text = FOOTER[index]
	_clear_errors()


## Which tab is showing: 0 for Create account, 1 for Log in.
func tab() -> int:
	return 0 if _forms[0].visible else 1


## Fills in fields (for tests). The keys are Online.check_sign_up()'s, and
## "login_email" and "login_password" for logging in.
func fill(values: Dictionary) -> void:
	for key: String in values:
		match key:
			"birthdate":
				var parts := String(values.birthdate).split("-")
				if parts.size() != 3:
					parts = PackedStringArray(["0", "0", "0"]) # none chosen
				_year.select(_year_index(parts[0].to_int()))
				_month.select(parts[1].to_int())
				_day.select(parts[2].to_int())
			"agreed":
				_agree.button_pressed = values.agreed
			_:
				(_inputs[key] as LineEdit).text = values[key]


## A field's box to type in (for tests).
func input(key: String) -> LineEdit:
	return _inputs[key]


## The sign-up form, as Online.sign_up() takes it.
func sign_up_form() -> Dictionary:
	return {"name": (_inputs.name as LineEdit).text, "username": (_inputs.username as LineEdit).text,
			"password": (_inputs.password as LineEdit).text, "email": (_inputs.email as LineEdit).text,
			"birthdate": _birthdate(), "agreed": _agree.button_pressed}


## What it says in red under a field ("" if nothing).
func error_for(key: String) -> String:
	var line: Label = _errors.get(key)
	return line.text if line != null and line.visible else ""


## What it says over the green button ("" if nothing).
func message() -> String:
	return _message.text


## Shows `text` over the green button, on a tab (0 Create account, 1 Log in),
## like why the login from last time didn't work.
func say(text: String, on_tab: int) -> void:
	show_tab(on_tab)
	_message.text = text


## Presses the green button: Sign up, or Log in.
func submit() -> void:
	await _on_submit()


## Plays offline instead, as the link under the sign does.
func play_offline() -> void:
	Online.play_offline()
	done.emit()


## Whether a password field shows what's typed (its eye is open).
func is_password_shown(key := "password") -> bool:
	return not (_inputs[key] as LineEdit).secret


## Presses a password field's eye (for tests).
func press_eye(key := "password") -> void:
	for child in (_inputs[key] as LineEdit).get_children():
		if child is EyeButton:
			child.pressed.emit()


## Opens one of the pages to read over the card (see Legal: "terms",
## "guidelines", "privacy", "disclaimer", or "child_safety").
func open_document(key: String) -> void:
	_document_title.text = Legal.title(key)
	_document_text.text = Legal.text(key)
	_document_text.scroll_to_line(0)
	_document.visible = true


## The page being read ("" if none).
func document_title() -> String:
	return _document_title.text if _document.visible else ""


func close_document() -> void:
	_document.visible = false


func _on_submit() -> void:
	if _busy:
		return
	_clear_errors()
	var problem := ""
	if tab() == 0:
		var form := sign_up_form()
		var problems := Online.check_sign_up(form)
		if not problems.is_empty():
			for key: String in problems:
				_show_error(key, problems[key])
			_message.text = "Please fix the parts in red."
			return
		_set_busy(true, "Signing up...")
		problem = await Online.sign_up(form)
	else:
		var login_email := (_inputs.login_email as LineEdit).text.strip_edges()
		var password := (_inputs.login_password as LineEdit).text
		if login_email == "":
			_show_error("login_email", "Please give your email.")
		if password == "":
			_show_error("login_password", "Please give your password.")
		if login_email == "" or password == "":
			return
		_set_busy(true, "Logging in...")
		problem = await Online.log_in(login_email, password)
	_set_busy(false)
	if problem == "":
		done.emit()
	elif "username" in problem:
		_show_error("username", problem)
	else:
		_message.text = problem


func _set_busy(busy: bool, doing := "") -> void:
	_busy = busy
	_submit.disabled = busy
	_submit.text = doing if busy else SUBMIT[tab()]


func _show_error(key: String, text: String) -> void:
	var line: Label = _errors[key]
	line.text = text
	line.visible = true


func _clear_errors() -> void:
	for line: Label in _errors.values():
		line.visible = false
	_message.text = ""


# "YYYY-MM-DD" from the three drop-downs, or "" if one isn't chosen.
func _birthdate() -> String:
	if _day.selected <= 0 or _month.selected <= 0 or _year.selected <= 0:
		return ""
	return "%04d-%02d-%02d" % [_year.get_item_text(_year.selected).to_int(), _month.selected, _day.selected]


func _year_index(year: int) -> int:
	for i in range(1, _year.item_count):
		if _year.get_item_text(i).to_int() == year:
			return i
	return 0


# --- Building it ----------------------------------------------------------------

func _build_card() -> void:
	var card := PanelContainer.new()
	card.position = CARD.position
	card.size = CARD.size
	card.add_theme_stylebox_override("panel", _box(WHITE, 26, 24.0, SHADOW, 18))
	add_child(card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	card.add_child(column)
	# The two tabs, in a rounded track: the chosen one is a white pill.
	var track := PanelContainer.new()
	track.add_theme_stylebox_override("panel", _box(FIELD, 22, 4.0))
	column.add_child(track)
	var row := HBoxContainer.new()
	track.add_child(row)
	var group := ButtonGroup.new()
	for i in 2:
		var tab_button := Button.new()
		tab_button.text = ["Create account", "Log in"][i]
		tab_button.toggle_mode = true
		tab_button.button_group = group
		tab_button.theme_type_variation = &"TabButton"
		tab_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab_button.focus_mode = Control.FOCUS_NONE
		tab_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		tab_button.pressed.connect(show_tab.bind(i))
		row.add_child(tab_button)
		_tabs.append(tab_button)
	# The form, which scrolls if it's taller than the card.
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	column.add_child(scroll)
	var room := MarginContainer.new() # room for the scroll bar
	room.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	room.add_theme_constant_override("margin_right", 12)
	scroll.add_child(room)
	var forms := VBoxContainer.new()
	room.add_child(forms)
	_forms.append(_build_sign_up(forms))
	_forms.append(_build_log_in(forms))
	_message = _small("", RED)
	column.add_child(_message)
	_submit = Button.new()
	_submit.theme_type_variation = &"SubmitButton"
	_submit.custom_minimum_size.y = 52.0
	_submit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_submit.pressed.connect(_on_submit)
	column.add_child(_submit)
	_footer = _small("", HINT)
	_footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_footer)


func _build_sign_up(parent: Container) -> VBoxContainer:
	var form := VBoxContainer.new()
	form.add_theme_constant_override("separation", 5)
	parent.add_child(form)
	_field(form, "name", "Your name", "e.g. Ama Mensah")
	var username := _field(form, "username", "Username", "ama_osu",
			"This is her name in Gold Coast. Other players see it over her head.")
	_prefix(username, "@")
	username.text_changed.connect(_keep_small.bind(username))
	var password := _field(form, "password", "Password", "",
			"Tip: 8 or more characters, and not 12345678, makes it harder to guess.", true)
	_eye(password)
	_field(form, "email", "Email", "you@email.com",
			"To log in, and later to reset your password. Check it's right: it can't be changed later.")
	form.add_child(_label("Date of birth"))
	var dates := HBoxContainer.new()
	dates.add_theme_constant_override("separation", 8)
	form.add_child(dates)
	var days := ["Day"]
	for day in range(1, 32):
		days.append(str(day))
	var years := ["Year"]
	var this_year: int = Time.get_date_dict_from_system().year
	for year in range(this_year - Online.MIN_AGE, this_year - 101, -1):
		years.append(str(year))
	_day = _choices(dates, days, 0.8)
	_month = _choices(dates, ["Month"] + MONTHS, 1.3)
	_year = _choices(dates, years, 1.0)
	_errors["birthdate"] = _error_line(form)
	# The box to tick, with the pages it agrees to.
	var agreeing := PanelContainer.new()
	agreeing.add_theme_stylebox_override("panel", _box(FIELD, 18, 14.0))
	form.add_child(agreeing)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	agreeing.add_child(row)
	_agree = TickBox.new()
	_agree.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(_agree)
	var words := RichTextLabel.new()
	words.bbcode_enabled = true
	words.fit_content = true
	words.scroll_active = false
	words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_theme_color_override("default_color", LABEL)
	words.add_theme_font_size_override("normal_font_size", 14)
	words.add_theme_font_size_override("bold_font_size", 14)
	words.add_theme_font_override("bold_font", _bold())
	words.text = "I'm [b]18+[/b] and I agree to the %s, %s, %s and %s, %s." % [_link("terms", "Terms"),
			_link("guidelines", "Community Guidelines"), _link("privacy", "Privacy Policy"),
			_link("disclaimer", "Disclaimer"), _link("child_safety", "Child safety")]
	words.meta_clicked.connect(func(page: Variant) -> void: open_document(String(page)))
	row.add_child(words)
	_errors["agreed"] = _error_line(form)
	return form


func _build_log_in(parent: Container) -> VBoxContainer:
	var form := VBoxContainer.new()
	form.add_theme_constant_override("separation", 5)
	parent.add_child(form)
	_field(form, "login_email", "Email", "you@email.com")
	_eye(_field(form, "login_password", "Password", "", "", true))
	form.add_child(_small("Forgot your password? Resetting it by email is coming soon.", HINT))
	return form


# A field: its label, the box to type in, a hint under it (if any), and a red
# line for mistakes (hidden until there's one).
func _field(form: VBoxContainer, key: String, title: String, placeholder: String, hint := "",
		secret := false) -> LineEdit:
	if form.get_child_count() > 0:
		var gap := Control.new()
		gap.custom_minimum_size.y = 4.0
		form.add_child(gap)
	form.add_child(_label(title))
	var input := LineEdit.new()
	input.placeholder_text = placeholder
	input.secret = secret
	input.custom_minimum_size.y = 46.0
	input.text_submitted.connect(func(_text: String) -> void: _on_submit())
	form.add_child(input)
	if hint != "":
		form.add_child(_small(hint, HINT))
	_inputs[key] = input
	_errors[key] = _error_line(form)
	return input


# Writing in front of what's typed, like the @ before a username.
func _prefix(input: LineEdit, text: String) -> void:
	input.add_theme_stylebox_override("normal", _field_box(false, 36.0))
	input.add_theme_stylebox_override("focus", _field_box(true, 36.0))
	var front := Label.new()
	front.text = text
	front.mouse_filter = Control.MOUSE_FILTER_IGNORE
	front.add_theme_color_override("font_color", INK)
	front.add_theme_font_size_override("font_size", 17)
	front.anchor_top = 0.5
	front.anchor_bottom = 0.5
	front.offset_left = 18.0
	front.offset_top = -12.0
	front.offset_bottom = 12.0
	input.add_child(front)


# The eye at the end of a password field, which shows or hides the password.
func _eye(input: LineEdit) -> void:
	input.add_theme_stylebox_override("normal", _field_box(false, 18.0, 50.0))
	input.add_theme_stylebox_override("focus", _field_box(true, 18.0, 50.0))
	var eye := EyeButton.new()
	eye.target = input
	eye.anchor_left = 1.0
	eye.anchor_right = 1.0
	eye.anchor_top = 0.5
	eye.anchor_bottom = 0.5
	eye.offset_left = -46.0
	eye.offset_right = -10.0
	eye.offset_top = -16.0
	eye.offset_bottom = 16.0
	input.add_child(eye)


# Usernames are small letters: whatever's typed becomes small, without an @.
func _keep_small(text: String, input: LineEdit) -> void:
	var small := text.to_lower().replace("@", "").replace(" ", "_")
	if small != text:
		var caret := input.caret_column
		input.text = small
		input.caret_column = mini(caret, small.length())


func _choices(row: HBoxContainer, items: Array, stretch: float) -> OptionButton:
	var choices := OptionButton.new()
	for item: String in items:
		choices.add_item(item)
	choices.select(0)
	choices.custom_minimum_size.y = 46.0
	choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choices.size_flags_stretch_ratio = stretch
	choices.fit_to_longest_item = false
	choices.get_popup().theme = theme
	row.add_child(choices)
	return choices


func _build_document() -> void:
	_document = PanelContainer.new()
	_document.position = CARD.position
	_document.size = CARD.size
	_document.add_theme_stylebox_override("panel", _box(WHITE, 26, 24.0, SHADOW, 18))
	_document.visible = false
	add_child(_document)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	_document.add_child(column)
	_document_title = Label.new()
	_document_title.add_theme_font_override("font", _bold())
	_document_title.add_theme_font_size_override("font_size", 22)
	_document_title.add_theme_color_override("font_color", INK)
	column.add_child(_document_title)
	_document_text = RichTextLabel.new()
	_document_text.bbcode_enabled = true
	_document_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_document_text.add_theme_color_override("default_color", LABEL)
	_document_text.add_theme_font_size_override("normal_font_size", 15)
	_document_text.add_theme_font_size_override("bold_font_size", 15)
	_document_text.add_theme_font_size_override("italics_font_size", 13)
	_document_text.add_theme_font_override("bold_font", _bold())
	column.add_child(_document_text)
	var back := Button.new()
	back.text = "Back"
	back.theme_type_variation = &"SubmitButton"
	back.custom_minimum_size.y = 48.0
	back.pressed.connect(close_document)
	column.add_child(back)


func _build_offline_link() -> void:
	var offline := LinkButton.new()
	offline.text = "No account? Play offline: single player, saved in this browser."
	offline.position = OFFLINE_AT
	offline.underline = LinkButton.UNDERLINE_MODE_ALWAYS
	offline.add_theme_color_override("font_color", Palette.color(Palette.ColorName.PAPER))
	offline.add_theme_color_override("font_hover_color", Palette.color(Palette.ColorName.KENTE_GOLD))
	offline.add_theme_color_override("font_pressed_color", Palette.color(Palette.ColorName.KENTE_GOLD))
	offline.add_theme_font_size_override("font_size", 17)
	offline.pressed.connect(play_offline)
	add_child(offline)


func _label(text: String) -> Label:
	var title := Label.new()
	title.text = text
	title.theme_type_variation = &"FieldLabel"
	return title


func _small(text: String, color: Color) -> Label:
	var line := Label.new()
	line.text = text
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.add_theme_color_override("font_color", color)
	line.add_theme_font_size_override("font_size", 12)
	return line


func _error_line(form: VBoxContainer) -> Label:
	var line := _small("", RED)
	line.visible = false
	form.add_child(line)
	return line


func _link(page: String, text: String) -> String:
	return "[color=#%s][url=%s]%s[/url][/color]" % [LINK.to_html(false), page, text]


func _bold() -> FontVariation:
	var bold := FontVariation.new()
	bold.base_font = ThemeDB.fallback_font
	bold.variation_embolden = 0.6
	return bold


func _box(color: Color, radius: int, margin: float, shadow := Color(0, 0, 0, 0), shadow_size := 0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	box.set_content_margin_all(margin)
	box.shadow_color = shadow
	box.shadow_size = shadow_size
	box.shadow_offset = Vector2(0.0, shadow_size * 0.35)
	return box


# A text box's pill: grey-blue, outlined in green while typing in it.
func _field_box(focused: bool, left := 18.0, right := 18.0) -> StyleBoxFlat:
	var box := _box(FIELD, 22, 12.0)
	box.content_margin_left = left
	box.content_margin_right = right
	if focused:
		box.border_color = FOCUS
		box.set_border_width_all(2)
	return box


# The green button, with a darker edge along its bottom.
func _button_box(color: Color) -> StyleBoxFlat:
	var box := _box(color, 24, 14.0)
	box.border_color = GREEN_DARK
	box.border_width_bottom = 4
	return box


func _make_theme() -> Theme:
	var made := Theme.new()
	made.default_font_size = 15
	made.set_color("font_color", "Label", LABEL)
	made.set_type_variation("FieldLabel", "Label")
	made.set_font("font", "FieldLabel", _bold())
	# Text boxes.
	made.set_stylebox("normal", "LineEdit", _field_box(false))
	made.set_stylebox("focus", "LineEdit", _field_box(true))
	made.set_color("font_color", "LineEdit", INK)
	made.set_color("font_placeholder_color", "LineEdit", PLACEHOLDER)
	made.set_color("caret_color", "LineEdit", INK)
	made.set_color("selection_color", "LineEdit", Color(GREEN, 0.3))
	made.set_font_size("font_size", "LineEdit", 17)
	# Drop-down lists, in the same pills.
	for state in ["normal", "hover", "pressed", "disabled"]:
		made.set_stylebox(state, "OptionButton", _field_box(false))
	var focus_ring := _field_box(true)
	focus_ring.bg_color = Color(0, 0, 0, 0)
	made.set_stylebox("focus", "OptionButton", focus_ring)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		made.set_color(state, "OptionButton", INK)
	made.set_icon("arrow", "OptionButton", _arrow())
	made.set_font_size("font_size", "OptionButton", 16)
	made.set_stylebox("panel", "PopupMenu", _box(WHITE, 14, 8.0, SHADOW, 10))
	made.set_stylebox("hover", "PopupMenu", _box(FIELD, 8, 4.0))
	made.set_color("font_color", "PopupMenu", INK)
	made.set_color("font_hover_color", "PopupMenu", INK)
	made.set_font_size("font_size", "PopupMenu", 15)
	# The tabs.
	made.set_type_variation("TabButton", "Button")
	made.set_stylebox("normal", "TabButton", _box(Color(1, 1, 1, 0), 18, 10.0))
	made.set_stylebox("hover", "TabButton", _box(Color(1, 1, 1, 0.5), 18, 10.0))
	made.set_stylebox("pressed", "TabButton", _box(WHITE, 18, 10.0, Color(0, 0, 0, 0.12), 4))
	made.set_stylebox("hover_pressed", "TabButton", _box(WHITE, 18, 10.0, Color(0, 0, 0, 0.12), 4))
	made.set_stylebox("focus", "TabButton", StyleBoxEmpty.new())
	made.set_color("font_color", "TabButton", HINT)
	for state in ["font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		made.set_color(state, "TabButton", INK)
	made.set_font("font", "TabButton", _bold())
	made.set_font_size("font_size", "TabButton", 16)
	# The green button.
	made.set_type_variation("SubmitButton", "Button")
	made.set_stylebox("normal", "SubmitButton", _button_box(GREEN))
	made.set_stylebox("hover", "SubmitButton", _button_box(GREEN_LIGHT))
	made.set_stylebox("pressed", "SubmitButton", _button_box(GREEN_DARK))
	made.set_stylebox("disabled", "SubmitButton", _button_box(Color("9fb5a8")))
	made.set_stylebox("focus", "SubmitButton", StyleBoxEmpty.new())
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_disabled_color",
			"font_focus_color"]:
		made.set_color(state, "SubmitButton", WHITE)
	made.set_font("font", "SubmitButton", _bold())
	made.set_font_size("font_size", "SubmitButton", 18)
	# A thin grey scroll bar.
	made.set_stylebox("scroll", "VScrollBar", StyleBoxEmpty.new())
	made.set_stylebox("grabber", "VScrollBar", _box(Color("cfd5de"), 4, 3.0))
	made.set_stylebox("grabber_highlight", "VScrollBar", _box(Color("b7bfcb"), 4, 3.0))
	made.set_stylebox("grabber_pressed", "VScrollBar", _box(Color("a3acb9"), 4, 3.0))
	return made


# The little down arrow on the drop-down lists.
func _arrow() -> ImageTexture:
	var image := Image.create(12, 7, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for y in 6:
		for x in range(y, 12 - y):
			image.set_pixel(x, y, HINT)
	return ImageTexture.create_from_image(image)


## A box to tick: white with a grey edge, or green with a white tick.
class TickBox extends Button:
	func _init() -> void:
		toggle_mode = true
		flat = true
		custom_minimum_size = Vector2(26.0, 26.0)
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		toggled.connect(func(_on: bool) -> void: queue_redraw())

	func _draw() -> void:
		var rect := Rect2(Vector2(2.0, 2.0), Vector2(22.0, 22.0))
		var box := StyleBoxFlat.new()
		box.set_corner_radius_all(6)
		if button_pressed:
			box.bg_color = AccountScreen.GREEN
		else:
			box.bg_color = AccountScreen.WHITE
			box.border_color = Color("8a94a3")
			box.set_border_width_all(2)
		draw_style_box(box, rect)
		if button_pressed:
			var tick := PackedVector2Array([rect.position + Vector2(5.0, 11.5), rect.position + Vector2(9.5, 16.0),
					rect.position + Vector2(17.0, 6.5)])
			draw_polyline(tick, AccountScreen.WHITE, 2.6, true)


## The eye at the end of a password field: press it to show the password (and
## again to hide it). Shown, it has a line through it.
class EyeButton extends Button:
	var target: LineEdit

	func _init() -> void:
		flat = true
		focus_mode = Control.FOCUS_NONE
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		tooltip_text = "Show the password"
		pressed.connect(_toggle)

	func _toggle() -> void:
		target.secret = not target.secret
		tooltip_text = "Show the password" if target.secret else "Hide the password"
		queue_redraw()

	func _draw() -> void:
		var middle := size / 2.0
		var color := Color("4b5563")
		var outline := PackedVector2Array()
		for i in 17:
			var t := i / 16.0
			outline.append(middle + Vector2(lerpf(-10.0, 10.0, t), -6.5 * sin(PI * t)))
		for i in 17:
			var t := i / 16.0
			outline.append(middle + Vector2(lerpf(10.0, -10.0, t), 6.5 * sin(PI * t)))
		draw_polyline(outline, color, 1.8, true)
		draw_circle(middle, 3.0, color)
		if target != null and not target.secret:
			draw_line(middle + Vector2(-9.0, 8.0), middle + Vector2(9.0, -8.0), color, 1.8, true)
