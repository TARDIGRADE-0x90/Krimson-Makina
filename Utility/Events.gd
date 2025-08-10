extends Node

signal game_state_changed

signal focus_active
signal focus_inactive

signal weapon_heat_updated(value: float)
signal core_overheated

signal new_target_hit(title: String, current_hp: float, max_hp: float)
signal enemy_uncalibrated
signal target_destroyed

signal gun_query_hovered(new_gun: GunData)
signal gun_query_exited
signal gun_selected

signal execution_ready(target_body: Node2D)
signal execution_unready
signal execution_initiated(body: Node2D)
signal execution_struck(body: Node2D)

signal player_died
signal player_death_finalized

signal all_clear
