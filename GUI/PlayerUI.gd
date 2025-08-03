extends CanvasLayer
class_name PlayerUI

"""
do later -
let WeaponHeat panel blink a bit upon reaching 0 before clearing
"""

const MSG_IDLE: String = "OPTICAL FEED :: ACTIVE"
const MSG_FOCUSED: String = "OPTICAL FEED :: SCANNING"
const MSG_COMBAT: String = "ENGAGING"

const COMBATANT_TEXT_BUFFER: String = " :: "

const CORE_HEAT_PREFIX: String = "GUILLOTINE-07 TEMPERATURE:"
const CORE_HEAT_SUFFIX: String = "° C FROM PEAK"
const CORE_HEAT_SUFFX_MAX: String = "° C FROM PEAK [FULLY COOLED]"

const WEAPON_MAX_HEAT_PREFIX: String = "MAX: "
const WEAPON_MAX_HEAT_SUFFIX: String = "° C"
const WEAPON_MAX_HEAT_SUFFIX_WARN: String = "° C [!!!]"
const OVERHEAT_WARNING: String = "[! OVERHEATING !]"

const WEAPON_HEAT_SUFFIX: String = "° C"

const WEAPON_HEAT_HEADER: String = "AUXILLARY HEAT"

const HEAT_WARN_FACTOR: float = 0.65

const CORE_HEAT_BAR_X_FACTOR: int = 2

const BATTLE_DELAY: float = 8.0
const DESTRUCTION_FLICKER: float = 1.4

@onready var OpticalLabel: Label = $OpticalIndicator/MarginContainer/VBoxContainer/OpticalLabel
@onready var EnemyLabel: Label = $OpticalIndicator/MarginContainer/VBoxContainer/EnemyLabel
@onready var DestructionLabel: Label = $OpticalIndicator/MarginContainer/VBoxContainer/DestructionLabel

@onready var CoreHeatPanel: Control = $CoreHeatPanel
@onready var CoreHeatHeader: Label = $CoreHeatPanel/MarginContainer/VBoxContainer/CoreHeatHeader
@onready var CoreHeatBar: ColorRect = $CoreHeatPanel/CoreHeatBar
@onready var CoreHeat: Label = $CoreHeatPanel/MarginContainer/VBoxContainer/CoreHeat

@onready var WeaponHeatPanel: Control = $WeaponHeatPanel
@onready var WeaponMaxHeat: Label = $WeaponHeatPanel/WeaponHeatLimit/WeaponMaxHeat
@onready var OverheatWarning: Label = $WeaponHeatPanel/WeaponHeatLimit/OverheatWarning
@onready var WeaponHeatBar: ColorRect = $WeaponHeatPanel/WeaponHeatBar
@onready var WeaponHeatHeader: Label = $WeaponHeatPanel/MarginContainer/VBoxContainer/WeaponHeatHeader
@onready var WeaponHeat: Label = $WeaponHeatPanel/MarginContainer/VBoxContainer/WeaponHeat

@onready var BattleDelay: Timer = $BattleDelay
@onready var DestroyFlicker: Timer = $DestroyFlicker

var fully_cooled: bool = false
var in_combat: bool = false
var combatant: String

func _ready() -> void:
	adjust_weapon_heat(0)
	initialize_battle_delay_timer()
	intialize_destroy_flicker()
	
	OpticalLabel.set_text(MSG_IDLE)
	EnemyLabel.set_visible(false)
	DestructionLabel.set_visible(false)
	
	CoreHeatHeader.set_text(CORE_HEAT_PREFIX)
	CoreHeat.set_text("%2.1f %s" % [Player.CORE_HEAT_INITIAL_MAX, CORE_HEAT_SUFFIX])
	CoreHeatBar.size.x = Player.CORE_HEAT_INITIAL_MAX * CORE_HEAT_BAR_X_FACTOR
	
	WeaponMaxHeat.set_text("%s %s" % [WEAPON_MAX_HEAT_PREFIX, WEAPON_MAX_HEAT_SUFFIX])
	WeaponHeatHeader.set_text(WEAPON_HEAT_HEADER)
	OverheatWarning.set_text(OVERHEAT_WARNING)
	OverheatWarning.set_visible(false)
	
	Events.weapon_heat_updated.connect(adjust_weapon_heat)
	Events.new_target_hit.connect(trigger_combat_behavior)
	Events.target_destroyed.connect(display_destruction_label)

func _process(delta) -> void:
	display_weapon_heat()
	display_core_heat()
	display_optical_text()

func initialize_battle_delay_timer() -> void:
	BattleDelay.set_wait_time(BATTLE_DELAY)
	BattleDelay.set_one_shot(true)
	BattleDelay.timeout.connect(clear_combat_behavior)

func intialize_destroy_flicker() -> void:
	DestroyFlicker.set_wait_time(DESTRUCTION_FLICKER)
	DestroyFlicker.set_one_shot(true)
	DestroyFlicker.timeout.connect(DestructionLabel.hide)

func display_weapon_heat() -> void:
	WeaponHeatPanel.visible = !fully_cooled
	
	if Global.player:
		if Global.player.weapon_heat >= Global.player.weapon_heat_max:
			OverheatWarning.set_visible(true)
			WeaponMaxHeat.set_text("%s %2.1f %s" % [WEAPON_MAX_HEAT_PREFIX, Global.player.weapon_heat_max, WEAPON_MAX_HEAT_SUFFIX_WARN])
		elif Global.player.weapon_heat >= Global.player.weapon_heat_max * HEAT_WARN_FACTOR:
			OverheatWarning.set_visible(false)
			WeaponMaxHeat.set_text("%s %2.1f %s" % [WEAPON_MAX_HEAT_PREFIX, Global.player.weapon_heat_max, WEAPON_MAX_HEAT_SUFFIX_WARN])
		else:
			OverheatWarning.set_visible(false)
			WeaponMaxHeat.set_text("%s %2.1f %s" % [WEAPON_MAX_HEAT_PREFIX, Global.player.weapon_heat_max, WEAPON_MAX_HEAT_SUFFIX])

func display_core_heat() -> void:
	if Global.player:
		
		if Global.player.core_heat == Global.player.core_heat_max:
			CoreHeat.set_text("%2.1f %s" % [Global.player.core_heat, CORE_HEAT_SUFFX_MAX])
		else:
			CoreHeat.set_text("%2.1f %s" % [Global.player.core_heat, CORE_HEAT_SUFFIX])
		
		CoreHeatBar.size.x = Global.player.core_heat * CORE_HEAT_BAR_X_FACTOR

func display_optical_text() -> void:
	if Global.player:
		
		if not in_combat:
			if Global.player.move_state == Global.player.MOVEMENT_STATES.FOCUS:
				OpticalLabel.set_text(MSG_FOCUSED)
			else:
				OpticalLabel.set_text(MSG_IDLE)
		else:
			OpticalLabel.set_text(MSG_COMBAT)

func adjust_weapon_heat(value: float) -> void:
	WeaponHeatBar.size.y = value
	WeaponHeat.set_text("%6.2f %s" % [value, WEAPON_HEAT_SUFFIX])
	
	fully_cooled = (value <= 0)

func trigger_combat_behavior(new_target: String, hp: float) -> void:
	DestructionLabel.set_visible(false)
	DestroyFlicker.stop()
	
	in_combat = true
	combatant = new_target
	EnemyLabel.set_text("%s %s %6.2f" % [combatant, COMBATANT_TEXT_BUFFER, hp])
	EnemyLabel.set_visible(true)
	BattleDelay.start()

func clear_combat_behavior() -> void:
	in_combat = false
	combatant = ""
	EnemyLabel.set_text("%s %s %6.2f" % [combatant, COMBATANT_TEXT_BUFFER, 0])
	EnemyLabel.set_visible(false)

func display_destruction_label() -> void:
	clear_combat_behavior()
	
	DestructionLabel.set_visible(true)
	DestroyFlicker.start()
