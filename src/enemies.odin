package main


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
}


get_enemy_spawn_timer :: proc(type: EnemyType) -> f32 {

	switch type {
	case .crawler:
		return 0.5
	}

	return 0

}
