package main


ShopItemType :: enum {
	Card,
	Relic,
}

ShopItem :: struct {
	relic_type: RelicType,
	card_type:  CardType,
	type:       ShopItemType,
	cost:       int,
	purchased:  bool,
}


get_shop_item_name :: proc(item: ShopItem) -> cstring {

	switch item.type {
	case .Card:
		return get_card_name(item.card_type)
	case .Relic:
		return get_relic_name(item.relic_type)
	}
	assert(false)
	return ""
}

import "core:math/rand"
get_random_item :: proc() -> ShopItem {
	item: ShopItem


	item.purchased = false
	item.type = auto_cast rand.int_max(len(ShopItemType))
	// Eventually we will do something around rarity
	if item.type == .Card {
		item.card_type = auto_cast (rand.int_max(len(CardType) - 1) + 1)
	} else {
		item.relic_type = auto_cast (rand.int_max(len(RelicType) - 1) + 1)
	}


	return item
}


get_shop_item_texture_name :: proc(item: ShopItem) -> Texture_Name {
	switch item.type {
	case .Card:
		return get_card_image_id(item.card_type)
	case .Relic:
		return get_relic_texture_name(item.relic_type)
	}
	assert(false)
	return .None
}

generate_shop_items :: proc() {
	for &item in game.shop_items {
		// pick a random relic or shop item
		// gather cost for item
		//

		item = get_random_item()
	}
}
