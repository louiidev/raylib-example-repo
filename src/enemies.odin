package main

import "core:fmt"

EnemyType :: enum {
	crawler,
}

Enemy :: struct {
	spawned:                bool,
	position:               Vector2,
	grid_position:          Vector2Int,
	active:                 bool,
	health:                 int,
	max_health:             int,
	type:                   EnemyType,
	enemy_spawn_timer:      f32,
	next_target_path_index: int,
	target_position:        Vector2,
	speed:                  f32,
	flipped:                bool,
	flash_timer:            f32,
	flash_value:            f32,
	flash_color:            Vector3,
}


get_enemy_spawn_timer :: proc(type: EnemyType) -> f32 {

	switch type {
	case .crawler:
		return 0.90
	}

	return 0.5

}


get_enemy_speed :: proc(type: EnemyType) -> f32 {

	switch type {
	case .crawler:
		return 20
	}

	return 1

}


get_enemy_health :: proc(type: EnemyType) -> int {

	switch type {
	case .crawler:
		return 2
	}

	return 1

}


damage_enemy :: proc(enemy: ^Enemy, dmg: int) {
	enemy.health -= dmg
	create_dmg_popup(dmg, enemy.position)
	enemy.flash_timer = 0.5
	if enemy.health <= 0 {
		enemy.active = false
	}
}
