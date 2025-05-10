package main

EntType :: enum {
	active,
	static, // static are for things like buildings etc
}


EntAnimationState :: enum {
	Idle,
	Attacking,
}

Entity :: struct {
	position: Vector2,
	flipped:                bool,
	range:                  int,
	active:                 bool,
	attack_amount:          int,
	attack_cooldown_time:   f32,
	attack_target_pos: Vector2,
	card_type:              CardType,
	grid_position:          Vector2Int,
	movable:                bool,
	ent_type:               EntType,
	animation_state: EntAnimationState,
}
