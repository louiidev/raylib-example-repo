package main

import "core:math"
import "core:math/rand"


TileOccupiedBy :: enum {
	nil,
	Dirt,
	Building,
	Resource,
}


Tile :: struct {
	grid_position:       Vector2Int,
	chunk_grid_position: Vector2Int,
	position:            Vector2,
	card_type:           CardType,
	walkable:            bool,
}


get_card_type_g_cost :: proc(type: CardType) -> int {
	#partial switch type {
	case .nil:
		return 0
	case .House, .AttackTower:
		return 40
	case .Warrior:
		return 1
	case .PoisionTile:
		return 0
	}

	return 0
}


// get_illumination_level_color :: proc(level: IlluminationLevel) -> Vector4 {
// 	switch level {
// 	case .Hidden:
// 		return {0, 0, 0, 0}
// 	case .AlmostHidden:
// 		return hex_to_rgb(0x232329)
// 	case .SemiHidden:
// 		return {0.3, 0.3, 0.3, 0.4}
// 	case .Shown:
// 		return COLOR_WHITE
// 	}

// 	return COLOR_WHITE
// }


ConveyorDirections :: enum {
	NORTH,
	EAST,
	SOUTH,
	WEST,
	NE,
	EN,
	SE,
	ES,
	NW,
	WN,
	SW,
	WS,
}

ConveyorType :: enum {
	SLOW,
	MID,
	FAST,
}
get_conveyor_speed :: proc(type: ConveyorType) -> f32 {
	switch (type) {
	case .SLOW:
		return 20
	case .MID:
		return 40
	case .FAST:
		return 60
	}

	assert(false)
	return {}
}


get_conveyor_direction :: proc(direction: ConveyorDirections) -> Vector2 {
	switch (direction) {
	case .EAST, .NE, .SE:
		return {1, 0}
	case .EN, .NORTH, .WN:
		return {0, 1}
	case .ES, .SOUTH, .WS:
		return {0, -1}
	case .WEST, .SW, .NW:
		return {-1, 0}
	}

	assert(false)
	return {}
}

ConveyorBelt :: struct {
	initial_direction:   ConveyorDirections,
	visual_direction:    ConveyorDirections,
	position:            Vector2,
	world_tile_position: Vector2Int,
	chunk_position:      Vector2Int,
	type:                ConveyorType,
}


get_animation_conveyor_frame :: proc(direction: ConveyorDirections) -> int {
	base_speed: f32 = 192 // A constant that keeps the animation consistent
	frame_count := 16
	speed: f32 = base_speed / f32(frame_count)
	#partial switch (direction) {
	case .NW, .NE, .EN, .SE, .ES, .SW, .WN, .WS:
		frame_count = 4

	}

	frame := int(game.world_time_elapsed * speed) % frame_count
	return frame
}

import "core:math/linalg"


TILE_SIZE: f32 : 16

div_floor :: proc(a, b: int) -> int {
	result := a / b
	if (a < 0 && a % b != 0) {
		result -= 1
	}
	return result
}


neighbour_directions: [4]Vector2Int = {{-1, 0}, {1, 0}, {0, 1}, {0, -1}}
all_neighbour_directions: [8]Vector2Int = {
	{-1, 0},
	{1, 0},
	{0, 1},
	{0, -1},
	{-1, -1},
	{1, 1},
	{-1, 1},
	{1, -1},
}


grid_to_world_pos :: proc(grid_pos: Vector2Int) -> Vector2 {
	return {auto_cast grid_pos.x * (16 + 3), auto_cast grid_pos.y * (16 + 3)}
}

world_to_grid_pos :: proc(world_pos: Vector2) -> Vector2Int {
	return {auto_cast world_pos.x / 19, auto_cast world_pos.y / 19}
}


is_valid_pos :: proc(pos: Vector2Int) -> bool {
	return pos.x >= 0 && pos.y >= 0 && pos.x < GRID_SIZE_X && pos.y < GRID_SIZE_Y
}


generate_resource :: proc(type: CardType) {

}
