package main
import "core:math/rand"
import "core:slice"


CardInteractiveStates :: enum {
	None,
	Hover,
	Selected,
}


Card :: struct {
	position:         Vector2,
	type:             CardType,
	cost:             int,
	scale:            Vector2,
	rotation:         f32,
	hover_cooldown:   f32,
	last_frame_state: CardInteractiveStates,
}


ActionType :: enum {
	Placement,
	Action,
}

CardType :: enum {
	nil,
	Warrior,
	House,
	AttackTower,
	PoisionTile,
	Axe,
}

get_card_range :: proc(card_type: CardType) -> int {
	#partial switch card_type {
	case .Warrior:
		return 1

	case .AttackTower:
		return 2
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
	case .Warrior, .AttackTower:
		return .active

	}


	return .static
}

get_card_action_type :: proc(card_type: CardType) -> ActionType {


	switch card_type {
	case .nil:
		assert(false)
	case .House, .Warrior, .AttackTower, .PoisionTile:
		return .Placement
	case .Axe:
		return .Action
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
	case .AttackTower:
		return 2
	case .PoisionTile:
		return 1

	case .Axe:
		return 0
	}

	return 1
}

get_card_entity_size :: proc(card_type: CardType) -> Vector2 {
	#partial switch card_type {
	case .AttackTower:
		return {TILE_SIZE, f32(42.0 / 32.0) * f32(TILE_SIZE)}
	}


	return {TILE_SIZE, TILE_SIZE}
}

get_card_image_id :: proc(card_type: CardType) -> Texture_Name {
	texture_name: Texture_Name
	switch card_type {
	case .nil:
	case .House:
		texture_name = .House
	case .Warrior:
		texture_name = .Warrior
	case .AttackTower:
		texture_name = .Attack_Tower
	case .PoisionTile:
		return .Poison_Tile

	case .Axe:
		return .Axe
	}


	return texture_name
}

import "core:c"
import "core:strings"

get_card_file_name :: proc(card_type: CardType) -> cstring {
	switch card_type {
	case .nil:
		assert(false)
	case .House:
		return "house_card.png"
	case .Warrior:
		return "warrior_card.png"
	case .AttackTower:
		return "attack_tower_card.png"
	case .PoisionTile:
		return "poison_tile_card.png"
	case .Axe:
		return "axe_card.png"
	}


	return ""
}

get_card_name :: proc(card_type: CardType) -> cstring {
	switch card_type {
	case .nil:
		assert(false)
	case .House:
		return "House"
	case .Warrior:
		return "Warrior"
	case .AttackTower:
		return "Attack Tower"
	case .PoisionTile:
		return "Poision Tile"
	case .Axe:
		return "Axe"
	}


	return ""
}


shuffle_deck :: proc() {
	for len(game.discard_pile) > 0 {
		random_card_index := rand.int_max(len(game.discard_pile))
		card_type := game.discard_pile[random_card_index]
		append(&game.in_run_deck, card_type)
		unordered_remove(&game.discard_pile, random_card_index)
	}
}

populate_deck :: proc() {
	clear(&game.in_run_deck)
	temp_deck_copy := slice.clone_to_dynamic(game.permanent_deck[:])
	defer delete(temp_deck_copy)
	for len(temp_deck_copy) > 0 {
		random_card_index := rand.int_max(len(temp_deck_copy))
		card_type := temp_deck_copy[random_card_index]
		append(&game.in_run_deck, card_type)
		unordered_remove(&temp_deck_copy, random_card_index)
	}
}


draw_card :: proc() {
	card_type := game.in_run_deck[0]
	ordered_remove(&game.in_run_deck, 0)

	card: Card
	card.type = card_type
	card.scale = {1, 1}
	card.cost = get_card_resource_cost(card_type)
	append(&game.hand, card)
}


remove_card_from_hand :: proc(hand_index: int) {
	card_type := game.hand[hand_index].type
	ordered_remove(&game.hand, hand_index)
	append(&game.discard_pile, card_type)
}

discard_hand :: proc() {
	for i := len(game.hand) - 1; i >= 0; i -= 1 {
		remove_card_from_hand(i)
	}

}


get_card_render_texture :: proc(card_type: CardType) -> Texture_Name {
	switch card_type {
	case .nil:
		assert(false)
	case .House:
		return .House_Card
	case .Warrior:
		return .Warrior_Card
	case .AttackTower:
		return .Attack_Tower_Card
	case .PoisionTile:
		return .Poison_Tile_Card
	case .Axe:
		return .Axe_Card
	}


	return .None
}


get_card_description :: proc(type: CardType) -> cstring {


	switch type {
	case .nil:
		assert(false)
	case .House:
		return "Every round it generates 2 gold"
	case .Warrior:
		return "Deals 1 damage per hit"
	case .AttackTower:
		return "Deals 2 damage per hit"
	case .PoisionTile:
		return "Applies 1 poison per hit"
	case .Axe:
		return "Gives 2 gold per tree chopped"
	}

	return ""
}
