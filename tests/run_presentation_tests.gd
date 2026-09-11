extends SceneTree

var _failures: Array[String] = []
func _init() -> void:
	_test_presentation_resources_load()
	_test_scene_button_contract()
	_test_scene_hud_contract()
	_test_inventory_hud_contract()
	_test_window_asset_mapping()
	_test_growth_stage_geometry()
	_test_phenotype_descriptor()
	_test_mutation_reveal_detection()
	_test_species_visual_data()
	_test_fruit_visual_state()
	if _failures.is_empty():
		print("GrowWeird presentation tests passed")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
func _test_presentation_resources_load() -> void:
	var paths := [
		"res://src/presentation/main/scene_controls.tscn",
		"res://src/presentation/main/pot_selector.gd",
		"res://src/presentation/main/scene_action_button.gd",
		"res://src/presentation/main/scene_draggable_panel.gd",
		"res://src/presentation/main/scene_controls_overlay.gd",
		"res://src/presentation/ui/ui_atlas.gd",
		"res://src/presentation/environment/window_view.gd",
		"res://src/presentation/plant/plant_view.gd",
		"res://src/presentation/plant/branch_mutation_renderer.gd",
		"res://src/presentation/plant/phenotype_resolver.gd",
		"res://src/presentation/plant/plant_visual_assembler.gd",
		"res://src/presentation/inventory/inventory_hud.gd",
		"res://src/presentation/inventory/inventory_hud.tscn",
		"res://src/presentation/inventory/inventory_item_dialogs.gd",
		"res://src/presentation/inventory/inventory_item_dialogs.tscn",
		"res://src/presentation/progression/progression_panel.gd",
		"res://src/presentation/shop/shop_panel.gd",
		"res://src/presentation/shop/shop_layout_editor.gd",
		"res://src/presentation/main/wallet_topup_panel.gd",
		"res://src/presentation/main/wallet_topup_panel.tscn",
	]
	for path in paths:
		_expect(load(path) != null, "presentation load failed: %s" % path)
func _test_scene_button_contract() -> void:
	var host := Control.new()
	host.size = Vector2(1000.0, 600.0)
	var button := SceneActionButton.new()
	button.size = Vector2(100.0, 40.0)
	button.action_id = &"water"
	host.add_child(button)
	button.apply_normalized_position(Vector2(0.5, 0.25))
	_expect(button.normalized_position().distance_to(Vector2(0.5, 0.25)) < 0.001, "scene buttons: normalized position must round-trip")
	_expect(SceneControlsOverlay.DEFAULT_POSITIONS.has("lighting"), "scene buttons: lighting control missing")
	_expect(SceneControlsOverlay.DEFAULT_POSITIONS.has("water"), "scene buttons: water control missing")
	_expect(not SceneControlsOverlay.DEFAULT_POSITIONS.has("spray"), "scene buttons: spray must be contextual under water")
	_expect(not SceneControlsOverlay.DEFAULT_POSITIONS.has("harvest"), "scene buttons: harvest button must be removed")
	_expect(not SceneControlsOverlay.DEFAULT_POSITIONS.has("recycle_plant"), "scene buttons: a potted plant must never expose Grind")
	_expect(SceneControlsOverlay.DEFAULT_POSITIONS.has("wallet"), "scene buttons: wallet block must be movable")
	_expect(SceneControlsOverlay.DEFAULT_POSITIONS.has("shop") and SceneControlsOverlay.DEFAULT_POSITIONS.has("tasks"), "scene buttons: shop and tasks atlas controls missing")
	host.free()
func _test_scene_hud_contract() -> void:
	var host := Control.new()
	host.size = Vector2(1000.0, 600.0)
	var panel := SceneDraggablePanel.new()
	panel.size = Vector2(240.0, 90.0)
	panel.layout_id = &"inventory"
	host.add_child(panel)
	panel.apply_normalized_position(Vector2(0.6, 0.7))
	_expect(panel.normalized_position().distance_to(Vector2(0.6, 0.7)) < 0.001, "scene HUD: draggable panels must use normalized coordinates")
	_expect(SceneControlsOverlay.DEFAULT_POSITIONS.has("fertilizers"), "scene HUD: fertilizer block must be movable")
	_expect(SceneControlsOverlay.DEFAULT_POSITIONS.has("pots"), "scene HUD: pot selector must be movable")
	_expect(SceneControlsOverlay.DEFAULT_POSITIONS.has("inventory"), "scene HUD: inventory block must be movable")
	var main_text := FileAccess.get_file_as_string("res://src/presentation/main/main.tscn")
	var hud_text := FileAccess.get_file_as_string("res://src/presentation/main/scene_controls.tscn")
	_expect(main_text.contains("Save HUD layout"), "scene HUD: explicit save layout button missing")
	_expect(hud_text.contains("WalletHud") and hud_text.contains("MoneyLabel") and hud_text.contains("ShopButton"), "scene HUD: balance and shop must share a wallet block")
	_expect(FileAccess.file_exists("res://assets/ui/hud_balance.png") and FileAccess.file_exists("res://assets/ui/buttons.png"), "scene HUD: new UI atlases are missing")
	_expect(FileAccess.get_file_as_string("res://src/presentation/main/scene_controls_overlay.gd").count("configure_warm_timer_hud") == 2 and FileAccess.get_file_as_string("res://src/presentation/ui/ui_atlas.gd").contains("static func warm_hud_style") and not FileAccess.file_exists("res://assets/ui/buttons_hover.png") and not FileAccess.get_file_as_string("res://src/presentation/ui/ui_atlas.gd").contains("BUTTONS_HOVER") and not FileAccess.get_file_as_string("res://src/presentation/main/energy_hud.tscn").contains("NextArt"), "scene HUD: shared programmatic timer HUD style is missing")
	_expect(FileAccess.get_file_as_string("res://src/presentation/inventory/inventory_hud.gd").contains("UiAtlas.HUD_INVENTORY") and FileAccess.get_file_as_string("res://src/presentation/inventory/inventory_hud.gd").contains("background2(1)"), "inventory HUD: inventory and three slot atlas art are not wired")
	_expect(hud_text.contains("OffersPanel") and hud_text.contains("RefreshOffer") and hud_text.contains("SkipOffer"), "scene HUD: fertilizers need refresh left and skip right controls")
	_expect(hud_text.contains("Vector2(520, 112)"), "scene HUD: fertilizer timer must center on the visible offer block")
	var cooldown_text := FileAccess.get_file_as_string("res://src/presentation/main/fertilizer_cooldown_overlay.tscn")
	_expect(cooldown_text.contains("CooldownOverlay") and cooldown_text.contains("Next fertilizers 01:00"), "scene HUD: fertilizer cooldown overlay is missing")
	_expect(FileAccess.get_file_as_string("res://src/presentation/ui/ui_atlas.gd").contains("_set_slot_hover"), "scene HUD: fertilizer slots need hover highlighting")
	_expect(FileAccess.get_file_as_string("res://src/presentation/ui/ui_atlas.gd").contains("ACTION_MODE_BUTTON_PRESS"), "scene HUD: fertilizer selection must fire on mouse press")
	_expect(FileAccess.get_file_as_string("res://src/presentation/main/main_screen.gd").count("button_down.connect(_on_offer_") == 3, "scene HUD: all fertilizer slots must connect directly on button down")
	_expect(hud_text.contains("PotSelector") and hud_text.contains("PreviousPot") and hud_text.contains("NextPot") and hud_text.contains("PotThumbnail"), "scene HUD: pot selector needs one thumbnail between navigation arrows")
	_expect(hud_text.contains("PotCircle") and hud_text.contains('name="PreviousPot" type="Button" parent="PotSelector/Layers"'), "scene HUD: pot circle must stay square with arrows outside")
	_expect(hud_text.contains('name="ShopButton" type="Button" parent="WalletHud/Layers"'), "scene HUD: balance plus hit area must use fixed atlas coordinates")
	_expect(hud_text.contains("WalletTopupPanel") and FileAccess.get_file_as_string("res://src/presentation/main/wallet_topup_panel.tscn").contains("Coin1000") and FileAccess.get_file_as_string("res://src/presentation/main/energy_topup_panel.tscn").contains("Energy30") and FileAccess.get_file_as_string("res://src/presentation/main/wallet_topup_panel.gd").contains("UiAtlas.configure_close_button(%CloseButton)") and FileAccess.get_file_as_string("res://src/presentation/main/energy_topup_panel.gd").contains("UiAtlas.configure_close_button(%CloseButton)"), "top-up HUD: coin and energy lot cards are missing")
	_expect(FileAccess.get_file_as_string("res://src/presentation/main/scene_controls_overlay.gd").contains("configure_hud_slot"), "scene HUD: fertilizer menu needs three separate atlas backgrounds")
	_expect(FileAccess.get_file_as_string("res://src/presentation/main/main_screen.gd").contains("_set_offer_icon"), "fertilizer HUD: item assets must use a reduced fitted icon")
	_expect(FileAccess.get_file_as_string("res://src/presentation/main/scene_controls_overlay.gd").contains('configure_button(get_node("TasksButton")'), "scene HUD: tasks button hover atlas is not configured")
	_expect(not hud_text.contains("RecyclePlantButton") and not FileAccess.get_file_as_string("res://src/presentation/main/main_screen.gd").contains("recycle_active_dead_plant"), "scene HUD: Grind must only be available for inventory items")
	_expect(FileAccess.get_file_as_string("res://src/presentation/main/scene_controls_overlay.gd").contains('(get_node("WaterOptions") as PanelContainer).add_theme_stylebox_override') and FileAccess.get_file_as_string("res://src/presentation/main/scene_controls_overlay.gd").contains('(get_node("LightingOptions") as PanelContainer).add_theme_stylebox_override'), "scene HUD: water and lighting dark popup backgrounds must be removed")
	_expect(not main_text.contains("PotsScroll"), "scene HUD: pot selector must not remain in the sidebar")
	var shop_scene := FileAccess.get_file_as_string("res://src/presentation/shop/shop_panel.tscn")
	var shop_script := FileAccess.get_file_as_string("res://src/presentation/shop/shop_panel.gd")
	_expect(hud_text.contains('instance=ExtResource("4_shop")') and hud_text.contains("z_index = 180"), "shop HUD: modal shop must render above every scene control")
	_expect(shop_script.contains('CATEGORIES := [&"plants", &"pots", &"seeds", &"fertilizers", &"decorations", &"mutagens"]'), "shop HUD: requested category tabs are incomplete")
	_expect(shop_scene.contains("ItemGrid") and shop_scene.contains("CategoryHud") and shop_scene.contains("Confirm"), "shop HUD: unified category grid or purchase confirmation is missing")
	_expect(not shop_scene.contains("CategoryTitle") and not shop_scene.contains("HoverDescription"), "shop HUD: category heading and permanent description must be removed")
	_expect(not shop_scene.contains('name="Balance"') and not shop_script.contains("BalanceFrame") and shop_scene.contains("anchor_top = 0.2") and shop_script.contains("CommerceUiStyle.shop_outer_panel()") and FileAccess.get_file_as_string("res://src/presentation/main/main_screen.gd").count("shop_container.visible") == 1, "shop HUD: redundant balance, thin frames, unsafe top offset, or background Cancel is present")
	_expect(shop_script.contains('"price": 1') and shop_script.contains("range(5)"), "shop HUD: categories must expose five one-coin test items")
	_expect(shop_script.contains("TextureRect.new()") and shop_script.contains("_quantity_badge") and shop_script.contains('&"cutting"') and shop_script.contains('&"potted_plant"'), "shop HUD: lot cards need previews, quantities, branches, and first-stage potted plants")
	_expect(shop_scene.contains("QuantityMinus") and shop_scene.contains("QuantityPlus") and shop_scene.contains("QuantityLabel") and shop_script.contains("_change_quantity"), "shop HUD: purchase dialog must expose bounded quantity controls")
	_expect(shop_scene.contains('[node name="ConfirmBackground" type="Panel" parent="Confirm"]') and shop_scene.contains("ConfirmBanner") and shop_scene.contains("CountBackground"), "shop HUD: layered buy dialog atlas art is missing")
	_expect(not shop_script.contains("ShopLayoutEditor") and not shop_script.contains('register(%Confirm'), "shop HUD: transaction layout must be fixed and shared instead of independently draggable")
	_expect(shop_scene.contains('theme_override_colors/font_color = Color(0.33, 0.18, 0.1, 1)') and shop_script.contains("TransactionDialogVisual.configure"), "shop HUD: purchase description must use the fixed shared transaction layout and dark brown text")
	_expect(shop_script.contains('_stock[item_id] = maxi(0') and shop_script.contains('if int(item.get("stock", 0)) > 0'), "shop HUD: purchased single-stock items must disappear")
	_expect(shop_script.contains("UiAtlas.CoinFace.new()") and shop_script.contains("TransactionDialogVisual.configure") and FileAccess.get_file_as_string("res://src/presentation/ui/transaction_dialog_visual.gd").contains("CommerceUiStyle.transaction_action"), "shop HUD: programmatic Buy and shared close controls are missing")
	_expect(not shop_script.contains("_register_static_layout_elements") and not shop_script.contains("handle_input(event)"), "shop HUD: buttons and blocks must not support manual layout editing")
	_expect(shop_script.contains("_configure_lot_button") and shop_script.contains("_lot_price_style") and shop_script.contains("_cutting_texture"), "shop HUD: lot cells, coins, and cutting atlas art must be wired")
	_expect(shop_script.contains("shop_title_texture") and shop_script.contains("shop_awning_texture"), "shop HUD: Shop title and awning atlas art are missing")
	_expect(not shop_script.contains("LOT_FRAMES") and not shop_script.contains("shop_lot_texture") and shop_script.contains("CommerceUiStyle.shop_lot"), "shop HUD: category lot cards must be programmatic")
	_expect(not shop_script.contains("register(name_label") and not shop_script.contains("register(preview") and shop_scene.contains("columns = 4"), "shop HUD: fixed four-column grid must fit eight non-draggable cards")
	_expect(not hud_text.contains("OfferLabel"), "scene HUD: fertilizer title label must be removed")
	_expect(hud_text.contains("WaterOptions") and hud_text.contains("SprayButton") and hud_text.contains("PourButton"), "scene HUD: water must expose spray and pour")
	_expect(not hud_text.contains("HarvestButton"), "scene HUD: harvest control still present")
	_expect(not main_text.contains("SoilView") and not main_text.contains("PlantSense"), "scene HUD: legacy pot/comfort overlays must stay removed")
	_expect(main_text.contains("TreeGrowthControls") and main_text.contains("preview only"), "scene HUD: isolated tree asset testing controls missing")
	_expect(main_text.contains("modulate = Color(1, 1, 1, 0)"), "scene HUD: legacy procedural plant renderer must not compete with asset rendering")
	var pot_visual_text := FileAccess.get_file_as_string("res://src/presentation/main/pot_visual.gd")
	_expect(pot_visual_text.contains("GROUND_TEXTURES[state.soil_moisture_stage()]") and pot_visual_text.contains("ground.queue_redraw()"), "pot visual: moisture stage must directly select and redraw the soil asset")
	_expect(FileAccess.get_file_as_string("res://src/presentation/main/pot_visual.tscn").contains("[node name=\"Ground\" type=\"TextureRect\" parent=\".\"]\nz_index = 2"), "pot visual: tree must render above the soil layer")
	var overlay := SceneControlsOverlay.new()
	overlay.size = Vector2(1000.0, 600.0)
	var water := SceneActionButton.new()
	water.action_id = &"water"
	water.size = Vector2(112.0, 38.0)
	overlay.add_child(water)
	host.add_child(overlay)
	overlay._collect_controls()
	overlay.reset_layout()
	_expect(water.normalized_position().distance_to(SceneControlsOverlay.DEFAULT_POSITIONS["water"]) < 0.001, "scene HUD: action button layout must be restored")
	water.apply_normalized_position(Vector2(0.4, 0.3))
	overlay._capture_layout()
	_expect((overlay.get("_layout") as Dictionary)["water"].distance_to(Vector2(0.4, 0.3)) < 0.001, "scene HUD: action button layout must be captured")
	overlay.free()
	host.free()
func _test_inventory_hud_contract() -> void:
	var hud_text := FileAccess.get_file_as_string("res://src/presentation/inventory/inventory_hud.tscn")
	var inventory_script := FileAccess.get_file_as_string("res://src/presentation/inventory/inventory_hud.gd")
	var dialogs_text := FileAccess.get_file_as_string("res://src/presentation/inventory/inventory_item_dialogs.tscn")
	var scene_text := FileAccess.get_file_as_string("res://src/presentation/main/scene_controls.tscn")
	_expect(hud_text.contains("VBoxContainer") and hud_text.contains("Items"), "inventory HUD: inventory must be vertical")
	_expect(hud_text.contains("offset_top = 81.0") and hud_text.contains("offset_bottom = -80.0"), "inventory HUD: cells must start ten pixels beyond the visible atlas arrows")
	_expect(hud_text.contains("Vector2(0, 358)") and hud_text.contains("separation = 2"), "inventory HUD: viewport must contain three non-overlapping 118px cells")
	_expect(hud_text.contains("anchor_left = 0.045") and hud_text.contains("anchor_right = 0.955"), "inventory HUD: enlarged cells must fit horizontally inside the unchanged frame")
	_expect(hud_text.contains("allow_scaling = true") and inventory_script.contains("_add_fitted_icon"), "inventory HUD: frame must scale while item art stays fitted inside each slot")
	_expect(inventory_script.contains("offset_left = 19.7") and inventory_script.contains("offset_right = -19.7"), "inventory HUD: item art must remain reduced inside its fixed slot")
	_expect(hud_text.contains("vertical_scroll_mode = 3"), "inventory HUD: native vertical scrollbar must stay hidden")
	_expect(hud_text.contains("Vector2(164, 520)"), "inventory HUD: outer frame size must remain unchanged")
	_expect(hud_text.contains('[node name="FrameContent" type="Control" parent="Layers"]') and hud_text.contains('parent="Layers/FrameContent"'), "inventory HUD: paging arrows must stay inside the visible frame")
	_expect(hud_text.count('type="TextureButton"') == 2, "inventory HUD: atlas arrows must use reliable texture buttons")
	_expect(inventory_script.contains("SCROLL_STEP") and inventory_script.contains("_scroll_inventory"), "inventory HUD: arrow paging behavior is missing")
	_expect(hud_text.contains("clip_contents = true") and hud_text.contains("z_index = 5"), "inventory HUD: cells and arrows must be clipped inside the frame")
	_expect(FileAccess.get_file_as_string("res://src/presentation/ui/ui_atlas.gd").contains("configure_inventory_arrow"), "inventory HUD: paging must use the arrow atlas asset")
	_expect(hud_text.contains("drag_handle_height = 0.0"), "inventory HUD: panel must be draggable outside item buttons")
	_expect(inventory_script.contains("MOUSE_FILTER_IGNORE") and hud_text.contains('[node name="Layers" type="Control" parent="."]\nlayout_mode = 2\nmouse_filter = 2'), "inventory HUD: transparent padding must not block Shop or Tasks")
	_expect(FileAccess.get_file_as_string("res://src/presentation/inventory/inventory_hud.gd").contains("extends SceneDraggablePanel"), "inventory HUD: must use shared draggable panel")
	_expect(FileAccess.get_file_as_string("res://src/presentation/main/scene_controls.tscn").count("ExtResource(\"5_inventory\")") == 1, "scene HUD: exactly one InventoryHud instance")
	_expect(dialogs_text.contains("RecycleAction") and dialogs_text.contains("SellAction") and dialogs_text.contains("UseAction"), "inventory HUD: item action menu incomplete")
	_expect(not dialogs_text.contains("CancelAction") and FileAccess.get_file_as_string("res://src/presentation/main/main_screen.gd").contains("inventory_dialogs.needs_scene_cancel()") and FileAccess.get_file_as_string("res://src/presentation/inventory/inventory_item_dialogs.gd").contains("return actions.visible or recycle_popup.visible"), "inventory HUD: item menu must use the shared scene cancel button")
	_expect(FileAccess.get_file_as_string("res://src/presentation/inventory/inventory_item_dialogs.gd").contains("TransactionDialogVisual.configure") and FileAccess.get_file_as_string("res://src/presentation/ui/transaction_dialog_visual.gd").contains("Vector2(466.0, 480.0)") and FileAccess.get_file_as_string("res://src/presentation/ui/transaction_dialog_visual.gd").contains("Rect2(93.0, 408.0, 280.0, 54.0)") and FileAccess.get_file_as_string("res://src/presentation/ui/ui_atlas.gd").contains("icon.offset_left = 6.0") and FileAccess.get_file_as_string("res://src/presentation/ui/transaction_dialog_visual.gd").contains("_configure_modal_dim(root)") and FileAccess.get_file_as_string("res://src/presentation/ui/transaction_dialog_visual.gd").contains("count_background\"] as TextureRect).texture = null") and FileAccess.get_file_as_string("res://src/presentation/ui/transaction_dialog_visual.gd").contains("CommerceUiStyle.transaction_action") and FileAccess.get_file_as_string("res://src/presentation/ui/ui_atlas.gd").contains("class CoinFace"), "inventory HUD: shared fixed modal transaction layout is incomplete")
	_expect(dialogs_text.contains('[node name="SellBackground" type="Panel" parent="SellPopup"]') and dialogs_text.contains("SellBanner") and dialogs_text.contains("SellPreview") and dialogs_text.contains("SellDescription"), "inventory HUD: sale popup must use the shared buy-sell layout")
	_expect(dialogs_text.contains("QuantityMinus") and dialogs_text.contains("QuantityPlus") and dialogs_text.contains("ValueLabel") and dialogs_text.contains("SellButton"), "inventory HUD: sale quantity/value controls missing")
	_expect(dialogs_text.contains("OutputLabel") and dialogs_text.contains("Grind into fertilizer"), "inventory HUD: recycling preview missing")
	_expect(scene_text.contains("CurtainsButton") and scene_text.contains("OpenWindowButton") and scene_text.contains("BlindsButton") and scene_text.contains("NormalLightButton"), "lighting HUD: four requested modes missing")
	var main_scene_text := FileAccess.get_file_as_string("res://src/presentation/main/main.tscn")
	_expect(main_scene_text.contains("CareGauge") and main_scene_text.contains("care_gauge.gd"), "care HUD: three-arc gauge is missing from the main scene")
	_expect(main_scene_text.contains('parent="Shell/Layout/ScenePanel/SceneRoot"') and main_scene_text.contains("z_index = 20"), "care HUD: gauge must render above the scene HUD")
	_expect(FileAccess.get_file_as_string("res://src/domain/services/care_gauge_service.gd").contains("evaluate_or_preview"), "care HUD: gauge must remain visible for a selected empty pot")
	_expect(FileAccess.get_file_as_string("res://src/presentation/inventory/inventory_hud.gd").contains('_genetic_title("Branch"'), "inventory HUD: pruned plant material must be shown as a branch")
	var item_art := FileAccess.get_file_as_string("res://src/presentation/inventory/inventory_item_art.gd")
	_expect(item_art.contains('kind == &"cutting"') and item_art.contains("UiAtlas.branch_texture()"), "inventory HUD: every branch icon must use buttons atlas frame 8-1")
	_expect(item_art.contains("FertilizerAssetCatalog.is_offer_id") and item_art.contains("FertilizerOfferArt.texture_for"), "inventory HUD: offered fertilizers must reuse their atlas asset instead of text")
	_expect(item_art.contains('"fertilizer:universal_fertilizer": Vector2i(0, 5)'), "inventory HUD: shop fertilizer must use atlas frame 1-6")
	_expect(item_art.contains('"fertilizer:compost_mix": Vector2i(3, 0)') and item_art.contains('"misc:dead_mouse": Vector2i(2, 5)'), "inventory HUD: recycled fertilizer and dead mouse atlas frames are missing")
	_expect(inventory_script.contains("_configure_fixed_slot(button)") and inventory_script.contains("button.clip_text = true") and inventory_script.contains("STRETCH_KEEP_ASPECT_CENTERED"), "inventory HUD: content must shrink or clip without resizing its fixed tile")
	_expect(inventory_script.contains("_set_item_hover"), "inventory HUD: items must react to hover")
	_expect(inventory_script.contains("_add_stack_badge(button, count)") and inventory_script.contains("PRESET_TOP_RIGHT"), "inventory HUD: stacked items must show their count over the asset's top-right corner")
	var controls_scene := FileAccess.get_file_as_string("res://src/presentation/main/scene_controls.tscn")
	var draggable_script := FileAccess.get_file_as_string("res://src/presentation/main/scene_draggable_panel.gd")
	var main_screen_script := FileAccess.get_file_as_string("res://src/presentation/main/main_screen.gd")
	_expect(controls_scene.contains("layout_id = &\"wallet\"\ndrag_handle_height = 120.0\nallow_scaling = true") and controls_scene.contains("z_index = 200") and FileAccess.get_file_as_string("res://src/presentation/main/energy_hud.tscn").contains("z_index = 200") and controls_scene.contains("offset_left = 198.0\noffset_top = 41.0\noffset_right = 236.0\noffset_bottom = 79.0") and FileAccess.get_file_as_string("res://src/presentation/main/energy_hud.tscn").contains("offset_left = 198.0\noffset_top = 41.0\noffset_right = 236.0\noffset_bottom = 79.0"), "balance HUD: coin and energy blocks must be scalable and above dialogs")
	_expect(FileAccess.get_file_as_string("res://src/presentation/main/wallet_topup_panel.tscn").contains('[node name="WalletTopupPanel" type="Control"]\nvisible = false') and controls_scene.count("z_index = 180") == 3 and FileAccess.get_file_as_string("res://src/presentation/shop/shop_panel.tscn").contains('[node name="Confirm" type="Control" parent="."]\nunique_name_in_owner = true\nz_index = 190\nz_as_relative = false') and dialogs_text.contains('[node name="SellPopup" type="Control" parent="."]\nvisible = false\nz_index = 190\nz_as_relative = false'), "modal HUD: top-ups and transaction confirmations must stay below balances and above other UI")
	_expect(FileAccess.get_file_as_string("res://src/presentation/ui/ui_atlas.gd").contains("energycoin_icon.png") and FileAccess.get_file_as_string("res://src/presentation/ui/ui_atlas.gd").contains("ENERGY_COIN_CELL := 256.0") and FileAccess.get_file_as_string("res://src/presentation/ui/ui_atlas.gd").contains("energy_coin_icon(2, 4) if energy else energy_coin_icon(2, 3)") and FileAccess.get_file_as_string("res://src/presentation/main/wallet_topup_panel.gd").contains("energy_coin_icon(2, 1)") and FileAccess.get_file_as_string("res://src/presentation/main/wallet_topup_panel.gd").contains("energy_coin_icon(1, 2)") and FileAccess.get_file_as_string("res://src/presentation/main/wallet_topup_panel.gd").contains("energy_coin_icon(1, 1)") and FileAccess.get_file_as_string("res://src/presentation/main/wallet_topup_panel.gd").contains("energy_coin_icon(1, 4)") and FileAccess.get_file_as_string("res://src/presentation/main/energy_topup_panel.gd").contains("energy_coin_icon(3, 3)") and FileAccess.get_file_as_string("res://src/presentation/main/energy_topup_panel.gd").contains("energy_coin_icon(3, 2)") and FileAccess.get_file_as_string("res://src/presentation/main/energy_topup_panel.gd").contains("energy_coin_icon(3, 4)"), "top-up HUD: all balance and lot icons must use their requested energycoin atlas frames")
	_expect(FileAccess.get_file_as_string("res://src/presentation/main/scene_controls_overlay.gd").contains("set_energy_topup_visible(false)") and FileAccess.get_file_as_string("res://src/presentation/main/scene_controls_overlay.gd").contains("set_wallet_topup_visible(false)") and FileAccess.get_file_as_string("res://src/presentation/main/wallet_topup_panel.gd").contains('curved_title($Window/MenuTitle, "COINS")') and FileAccess.get_file_as_string("res://src/presentation/main/energy_topup_panel.gd").contains('curved_title($Window/MenuTitle, "ENERGY")') and FileAccess.get_file_as_string("res://src/presentation/ui/ui_atlas.gd").contains("CommerceUiStyle.topup_button") and FileAccess.get_file_as_string("res://src/presentation/main/wallet_topup_panel.tscn").contains("offset_left = -96.0") and FileAccess.get_file_as_string("res://src/presentation/main/energy_hud.tscn").contains("offset_left = 48.0\noffset_top = 80.0\noffset_right = 218.0"), "wallet HUD: switching, curved titles, programmatic buttons, and timer placement are required")
	_expect(main_screen_script.count("disabled = ids.is_empty()") >= 2, "fertilizer HUD: Skip and Refresh must stay disabled during the next-batch timer")
	_expect(main_screen_script.contains("Fertilizer added to inventory."), "fertilizer HUD: selecting an offer must report inventory acquisition instead of immediate use")
	_expect(main_screen_script.contains("active_pot().is_empty()") and main_screen_script.contains("GameApp.plant_cutting(item_id, GameApp.active_pot().pot_id)"), "inventory HUD: a branch must plant directly into the selected empty pot")
	_expect(ResourceActions.FERTILIZER == &"fertilizer", "inventory HUD: fertilizer stack economy kind missing")
	var rules := load("res://content/config/default_game_rules.tres") as GameRules
	var starter := NewGameFactory.create(rules)
	_expect(starter.inventory.cuttings.size() == 1, "inventory HUD: new games need one starter item for interaction testing")
	_expect(starter.pots[0].plant != null and starter.inventory.seeds.size() == 1, "inventory HUD: first pot sprout and starter seed are missing")
	_expect(starter.inventory.misc.has("dead_mouse") and InventoryService.fertilizer_count(starter.inventory, RecyclingService.COMPOST_ID) == 0, "inventory HUD: recycled fertilizer must only appear after grinding")
func _test_window_asset_mapping() -> void:
	var view := WindowView.new()
	view.set_environment(PotState.LightMode.DIRECT, false)
	_expect(view.texture == WindowView.SUNNY, "window art: normal light must use window_01")
	view.set_environment(PotState.LightMode.DARK, false)
	_expect(view.texture == WindowView.CURTAINS, "window art: curtains mode must use window_02")
	view.set_environment(PotState.LightMode.DIRECT, true)
	_expect(view.texture == WindowView.VENTILATION, "window art: open window must use window_03")
	view.set_environment(PotState.LightMode.DIFFUSED, false)
	_expect(view.texture == WindowView.BLINDS, "window art: blinds mode must use window_04")
	view.free()

func _test_growth_stage_geometry() -> void:
	var pot_preview := (load("res://src/presentation/main/pot_visual.tscn") as PackedScene).instantiate() as PotVisual
	root.add_child(pot_preview)
	var pot_state := PotState.new()
	pot_state.soil_moisture = 0.30
	pot_preview.set_pot_state(pot_state)
	var dry_ground := pot_preview.ground.texture
	pot_state.moisten_soil_one_stage()
	pot_preview.set_pot_state(pot_state)
	_expect(pot_preview.ground.texture != dry_ground, "pot visual: one pour must replace the displayed ground asset")
	pot_preview.free()
	var preview_scene := load("res://src/presentation/main/tree_growth_preview.tscn") as PackedScene
	var preview := preview_scene.instantiate() as TreeGrowthPreview
	root.add_child(preview)
	_expect(preview.get_node_or_null("Tree/LeftHover") != null, "tree preview: left hover asset path is invalid")
	_expect(preview.get_node_or_null("Tree/RightHover") != null, "tree preview: right hover asset path is invalid")
	var leaf_editor := preview.get_node_or_null("Tree/LeafLayout") as LeafLayoutEditor
	var flower_editor := preview.get_node_or_null("Tree/FlowerLayout") as FlowerLayoutEditor
	_expect(leaf_editor != null and LeafLayoutEditor.FIRST_TREE_STAGE == 4 and LeafLayoutEditor.LAST_TREE_STAGE == 13, "leaf layout: editor must cover tree_05 through tree_14")
	_expect(flower_editor != null and FileAccess.file_exists("res://content/visual/tree_flower_layouts.json"), "flower layout: independent editor and storage are missing")
	_expect(FileAccess.get_file_as_string("res://src/presentation/main/leaf_layout_editor.gd").contains("scale_variance") and FileAccess.get_file_as_string("res://src/presentation/main/leaf_layout_editor.gd").contains("direction_variance"), "leaf layout: point randomization parameters are missing")
	_expect(FileAccess.get_file_as_string("res://src/presentation/main/leaf_layout_controls.gd").contains("find_child(String(editor_node_name)"), "placement layout: controls must resolve either editor without a fragile serialized NodePath")
	leaf_editor.layouts = {"5": [{"x": 0.5, "y": 0.5, "scale": 1.0, "angle": 0.0, "scale_variance": 1.0, "direction_variance": 0.5}]}
	leaf_editor.selected_index = 0
	leaf_editor.set_stage(4)
	_expect(leaf_editor.selected_index == 0, "leaf layout: refresh of the same tree stage must preserve selection")
	leaf_editor._scale_selected(1.12)
	leaf_editor._rotate_selected(deg_to_rad(5.0))
	var edited_leaf: Dictionary = (leaf_editor.layouts["5"] as Array)[0]
	_expect(float(edited_leaf["scale"]) > 1.0 and float(edited_leaf["angle"]) > 0.0, "leaf layout: wheel scale and Shift-wheel rotation must update the selected leaf")
	preview.set_plant(null)
	preview.preview_stage_for_testing(3)
	_expect(preview.visible and preview.stage == 3, "tree preview: test selection must reveal the selected asset without a plant")
	preview.set_plant(null)
	_expect(preview.visible and preview.stage == 3, "tree preview: game refresh must not hide an active test preview")
	var plant_for_pruning := _plant()
	plant_for_pruning.growth_ratio = 1.0; plant_for_pruning.growth_cycle_index = 8
	preview.set_plant(plant_for_pruning)
	preview.clear_testing_preview()
	_expect(preview.stage == 7 and preview.has_prunable_branch(), "tree preview: prune mode must leave test preview and restore domain branches")
	preview.free()
	var plant := _plant()
	plant.growth_cycle_index = 0
	_expect(TreeGrowthPreview.stage_for(plant) == -1, "tree preview: planted seed must stay underground during its first gauge cycle")
	plant.growth_cycle_index = 1
	_expect(TreeGrowthPreview.stage_for(plant) == 0, "tree preview: first sprout must appear after the first completed gauge cycle")
	plant.growth_cycle_index = 8
	_expect(TreeGrowthPreview.stage_for(plant) == 7, "tree preview: intact mature plant must use the two-branch asset")
	plant.growth_cycle_index = 4
	_expect(TreeGrowthPreview.stage_for(plant) == 3, "tree preview: each completed gauge cycle must advance one growth asset")
	plant.growth_cycle_index = 5
	_expect(TreeGrowthPreview.stage_for(plant) == 4, "tree preview: a planted branch must immediately use tree_05")
	plant.cut_branch(&"left")
	_expect(TreeGrowthPreview.stage_for(plant) == 11, "tree preview: branch removal must select the left-cut asset without a stump")
	plant.cut_branch(&"right")
	_expect(TreeGrowthPreview.stage_for(plant) == 13, "tree preview: two branch removals must select the no-stump asset")
	plant.initialize_native_branches()
	plant.growth_ratio = 0.05
	var young := PlantVisualAssembler.build(Vector2(600.0, 400.0), plant)
	plant.growth_ratio = 0.8
	var mature := PlantVisualAssembler.build(Vector2(600.0, 400.0), plant)
	for slot in BranchState.VALID_SLOTS:
		var young_length := _slot_length(young, slot)
		var mature_length := _slot_length(mature, slot)
		_expect(mature_length > young_length, "growth view: %s branch should visibly expand with growth" % String(slot))

func _test_phenotype_descriptor() -> void:
	var branch := BranchState.new()
	branch.add_trait(&"thorns", 2)
	branch.add_trait(&"bloom", 3)
	branch.add_trait(&"glow", 1)
	branch.add_trait(&"fungi", 2)
	branch.add_trait(&"bark_armor", 1)
	branch.add_trait(&"lure_bloom", 1)
	branch.add_trait(&"crystal_thorns", 1)
	branch.add_trait(&"luminous_fungus", 1)
	branch.add_trait(&"hooks", 2)
	branch.add_trait(&"mineral_nodes", 1)
	branch.add_trait(&"crown_bloom", 1)
	branch.add_trait(&"toxic_sacs", 1)
	var phenotype := PhenotypeResolver.resolve_branch(branch)
	_expect(int(phenotype["thorn_count"]) > 0, "phenotype: thorns must be visible")
	_expect(int(phenotype["hook_count"]) > 0, "phenotype: hooks must be visible")
	_expect(int(phenotype["flower_count"]) > 0, "phenotype: bloom/lure must be visible")
	_expect(float(phenotype["crown_bloom_strength"]) > 0.0, "phenotype: crown bloom must affect flowers")
	_expect(float(phenotype["glow_strength"]) > 0.0, "phenotype: glow must be visible")
	_expect(int(phenotype["fungus_count"]) > 0, "phenotype: fungi must be visible")
	_expect(float(phenotype["branch_width_bonus"]) > 0.0, "phenotype: bark/mineral growth must affect silhouette")
	_expect(int(phenotype["mineral_node_count"]) > 0, "phenotype: mineral nodes must be visible")
	_expect(int(phenotype["toxic_sac_count"]) > 0, "phenotype: toxic sacs must be visible")
	_expect(int(phenotype["crystal_thorn_count"]) > 0, "phenotype: crystal thorns must be visible")
	_expect(float(phenotype["fungus_glow"]) > 0.0, "phenotype: luminous fungus must glow")

func _test_mutation_reveal_detection() -> void:
	var plant := _plant()
	var view := PlantView.new()
	view.set_process(false)
	view.set_plant(plant)
	_expect(not view.is_processing(), "mutation reveal: initial specimen should not animate as a mutation")
	plant.branch_at(&"left").add_trait(&"hooks", 1)
	view.set_plant(plant)
	_expect(view.is_processing(), "mutation reveal: increased branch trait should start reveal animation")
	view.free()

func _test_species_visual_data() -> void:
	var starter := load("res://content/plants/starter_sprout.tres") as PlantSpeciesDefinition
	var shade := load("res://content/plants/shade_fern.tres") as PlantSpeciesDefinition
	var sun := load("res://content/plants/sun_creeper.tres") as PlantSpeciesDefinition
	if starter == null or shade == null or sun == null:
		_expect(false, "species presentation: species resources failed to load")
		return
	_expect(shade.leaf_color != starter.leaf_color, "species presentation: shade fern should have distinct palette")
	_expect(sun.fruit_color != starter.fruit_color, "species presentation: sun creeper should have distinct fruit palette")

func _test_fruit_visual_state() -> void:
	var fruit := GrowingFruitState.new()
	fruit.progress = 0.99
	_expect(not fruit.is_ready(), "fruit presentation: unripe fruit marked ready")
	fruit.progress = 1.0
	fruit.hybrid = true
	_expect(fruit.is_ready() and fruit.hybrid, "fruit presentation: ripe hybrid state unavailable")
	_expect(PlantView.MODE_HARVEST == &"harvest", "fruit presentation: harvest interaction mode missing")
func _slot_length(layout: Dictionary, slot: StringName) -> float:
	var slots: Dictionary = layout["slots"]
	var descriptor: Dictionary = slots[String(slot)]
	var start: Vector2 = descriptor["start"]
	var end: Vector2 = descriptor["end"]
	return start.distance_to(end)
func _plant() -> PlantState:
	var plant := PlantState.new()
	plant.instance_id = "presentation-test"
	plant.species_id = &"starter_sprout"
	plant.initialize_native_branches()
	return plant
func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
