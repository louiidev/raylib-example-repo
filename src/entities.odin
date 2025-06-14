package main

EntType :: enum {
	active,
	static, // static are for things like buildings etc
}


EntAttackRangeStyle :: enum {
	Straight,
	Circular,
}


EntAnimationState :: enum {
	Idle,
	Attacking,
}

EntAttackStyle :: enum {
	Meele,
	Ranged,
}

Entity :: struct {
	position:                Vector2,
	flipped:                 bool,
	range:                   int,
	active:                  bool,
	attack_amount:           int,
	attack_cooldown_time:    f32,
	attack_target_direction: Vector2,
	card_type:               CardType,
	grid_position:           Vector2Int,
	movable:                 bool,
	ent_type:                EntType,
	animation_state:         EntAnimationState,
}


get_attack_range_style :: proc(type: CardType) -> EntAttackRangeStyle {
	#partial switch type {
	case .AttackTower:
		return .Circular
	}

	return .Straight
}


get_attack_style :: proc(type: CardType) -> EntAttackStyle {
	#partial switch type {
	case .AttackTower:
		return .Ranged
	}

	return .Meele
}

get_attack_positions :: proc(
	base_position: Vector2Int,
	range: int,
	card_type: CardType,
) -> [dynamic]Vector2Int {
	positions: [dynamic]Vector2Int
	positions.allocator = temp_allocator()


	if get_attack_range_style(card_type) == .Straight {
		loop: for r := 1; r <= range; r += 1 {
			for dir in neighbour_directions {
				append(&positions, dir)
			}
		}
	} else {
		placed_positions := make(map[Vector2Int]bool)
		defer delete(placed_positions)

		for r := 1; r <= range; r += 1 {
			for dir in all_neighbour_directions {
				for p_dir in neighbour_directions {
					pos := base_position + ((p_dir + dir) * r)
					if placed_positions[pos] == false &&
					   euclidean_distance(pos, base_position) <= f32(range) {
						placed_positions[pos] = true
						append(&positions, ((p_dir + dir) * r))
					}
				}

			}
		}


	}


	return positions
}

get_entity_tile_placement_pos :: proc(card_type: CardType) -> Vector2 {
	pos: Vector2 = {}

	#partial switch card_type {
	case .AttackTower:
		{
			return {0, 5}
		}
	case .House, .Warrior:
		return {0, 3}

	}


	return pos
}


// How much money does this ent generate at the end of a round
get_money_value_end_of_round :: proc(card_type: CardType) -> int {
	#partial switch card_type {
	case .House:
		return 1
	}

	return 0
}
