class_name PotSelector
extends SceneDraggablePanel

signal pot_selected(pot_id: String)

const POT_TEXTURES := [
	preload("res://assets/pot/pot_01.png"),
	preload("res://assets/pot/pot_02.png"),
	preload("res://assets/pot/pot_03.png"),
	preload("res://assets/pot/pot_04.png"),
	preload("res://assets/pot/pot_05.png"),
]

@onready var previous_button: Button = $Layers/PreviousPot
@onready var thumbnail: TextureRect = $Layers/PotThumbnail
@onready var next_button: Button = $Layers/NextPot

var _state: GameState
var _planting_target := false
var _last_signature := ""
var _index_hud: PanelContainer
var _index_label: Label
var _index_tween: Tween
var _pot_hovered := false

func _ready() -> void:
	super()
	previous_button.button_down.connect(_select_offset.bind(-1))
	next_button.button_down.connect(_select_offset.bind(1))
	_build_index_hud(); mouse_entered.connect(_on_pot_hover.bind(true)); mouse_exited.connect(_on_pot_hover.bind(false))

func set_state(state: GameState, planting_target: bool) -> void:
	_state = state
	_planting_target = planting_target
	var signature := _signature(state, planting_target)
	if signature == _last_signature:
		return
	_last_signature = signature
	_refresh_view()

func invalidate() -> void:
	_last_signature = ""

func _refresh_view() -> void:
	var pots := _selectable_pots()
	var active := _active_pot()
	if active == null and not pots.is_empty():
		active = pots[0]
	var has_pot := active != null
	thumbnail.visible = has_pot
	previous_button.disabled = pots.size() <= 1
	next_button.disabled = pots.size() <= 1
	if not has_pot:
		tooltip_text = "No available pots"
		return
	thumbnail.texture = POT_TEXTURES[_pot_index(active.pot_id)]
	var contents := "Empty" if active.is_empty() else String(active.plant.species_id).replace("_", " ").capitalize()
	tooltip_text = "%s · %s" % [active.pot_id, contents]
	thumbnail.tooltip_text = tooltip_text

func _select_offset(offset: int) -> void:
	var pots := _selectable_pots()
	if pots.size() <= 1:
		return
	var current_index := 0
	for index in range(pots.size()):
		if pots[index].pot_id == _state.active_pot_id:
			current_index = index
			break
	var next: PotState = pots[posmod(current_index + offset, pots.size())]
	pot_selected.emit(next.pot_id)
	call_deferred("_show_index_hud")

func _selectable_pots() -> Array[PotState]:
	var result: Array[PotState] = []
	if _state == null:
		return result
	for pot in _state.pots:
		result.append(pot)
	return result

func _active_pot() -> PotState:
	if _state == null:
		return null
	for pot in _state.pots:
		if pot.pot_id == _state.active_pot_id:
			return pot
	return null

func _signature(state: GameState, planting_target: bool) -> String:
	if state == null:
		return "null"
	var parts: Array[String] = [state.active_pot_id, str(planting_target)]
	for pot in state.pots:
		parts.append("%s:%s" % [pot.pot_id, "empty" if pot.is_empty() else pot.plant.instance_id])
	return "|".join(parts)

func _pot_index(pot_id: String) -> int:
	return PotVisual.index_for_id(pot_id, POT_TEXTURES.size())

func _build_index_hud() -> void:
	_index_hud = PanelContainer.new(); _index_hud.name = "PotIndexHud"; _index_hud.position = Vector2(35.0, 88.0); _index_hud.size = Vector2(170.0, 24.0); _index_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE; _index_hud.modulate.a = 0.0; _index_hud.visible = false; add_child(_index_hud)
	_index_label = Label.new(); _index_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; _index_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; _index_label.add_theme_font_size_override(&"font_size", 14); _index_hud.add_child(_index_label); UiAtlas.configure_warm_timer_hud(_index_hud, _index_label)

func _on_pot_hover(hovered: bool) -> void:
	_pot_hovered = hovered
	if hovered: _show_index_hud()
	else: _schedule_index_fade()

func _show_index_hud() -> void:
	var pots := _selectable_pots(); var active := _active_pot(); var index := pots.find(active)
	_index_label.text = "%d / %d" % [maxi(0, index) + 1, pots.size()]; _index_hud.visible = not pots.is_empty(); _index_hud.modulate.a = 1.0
	if _index_tween != null: _index_tween.kill()
	if not _pot_hovered: _schedule_index_fade()

func _schedule_index_fade() -> void:
	if _index_tween != null: _index_tween.kill()
	_index_tween = create_tween(); _index_tween.tween_interval(0.7); _index_tween.tween_property(_index_hud, "modulate:a", 0.0, 0.45); _index_tween.tween_callback(func() -> void: _index_hud.visible = false)
