package main


Card :: struct {
	position: Vector2,
	type:     CardType,
	cost:     int,
}


ActionType :: enum {
	Placement,
	Action,
}

CardType :: enum {
	nil,
	Warrior,
	House,
}

get_card_range :: proc(card_type: CardType) -> int {
	#partial switch card_type {
	case .Warrior:
		return 1
	}


	return 0
}

get_card_movable :: proc(card_type: CardType) -> bool {
	#partial switch card_type {
	case .Warrior:
		return true
	}


	return false
}


get_card_ent_type :: proc(card_type: CardType) -> EntType {
	#partial switch card_type {
	case .Warrior:
		return .active
	}


	return .static
}

get_card_action_type :: proc(card_type: CardType) -> ActionType {


	switch card_type {
	case .nil:
		assert(false)
	case .House, .Warrior:
		return .Placement
	}


	return .Action
}


get_card_resource_cost :: proc(card_type: CardType) -> int {
	switch card_type {
	case .nil:
		assert(false)
	case .House:
		return 1
	case .Warrior:
		return 2
	}

	return {}
}


get_card_image_id :: proc(card_type: CardType) -> Texture_Name {
	texture_name: Texture_Name
	switch card_type {
	case .nil:
	case .House:
		texture_name = .House
	case .Warrior:
		texture_name = .Warrior
	}


	return texture_name
}


get_tile_placement_pos :: proc(card_type: CardType) -> Vector2 {
	pos: Vector2 = {}

	#partial switch card_type {

	case .House:
		return {0, 1}
	}



	return pos
}


get_card_name :: proc(card_type: CardType) -> cstring {
	switch card_type {
		case .nil:
			assert(false)
		case .House:
			return "House"
		case .Warrior:
			return "Warrior"
		}


		return ""
}