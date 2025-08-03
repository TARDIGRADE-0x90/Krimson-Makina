extends Node

signal game_state_changed

signal focus_active
signal focus_inactive

signal weapon_heat_updated(value: float)
signal core_overheated

signal new_target_hit(title: String, current_hp: float)
signal target_destroyed
