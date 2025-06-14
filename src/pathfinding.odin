


package main

import "core:math"

manhattan_dist :: proc(a: Vector2Int, b: Vector2Int) -> f32 {
	return math.abs(f32(a.x) - f32(b.x)) + math.abs(f32(a.y) - f32(b.y))
}


euclidean_distance :: proc(a, b: Vector2Int) -> f32 {
	delta_x :f32 = auto_cast (b.x - a.x)
	delta_y :f32= auto_cast (b.y - a.y)
	return math.sqrt(delta_x * delta_x + delta_y * delta_y)
}
CardinalDirection :: enum {
	North,
	East,
	South,
	West,
}

ArrowTileType :: enum {
	Straight,
	Curved,
	End,
}


match_tile :: proc(in_dir, out_dir: Vector2Int) -> ArrowTileType {
	if in_dir == out_dir {
		return .Straight
	} else {
		log(in_dir, out_dir)
		return .Curved // Further refine to pick the correct curve
	}
}


NodePath :: struct {
	enemies:         [dynamic]Enemy,
	path:            [dynamic]Vector2Int,
	start_direction: CardinalDirection,
	start_position:  Vector2Int,
}

Node :: struct {
	position:         Vector2Int,
	travel_g_cost:    f32,
	g:                f32, // distance from start node
	h:                f32, // distance from target node
	walkable:         bool,
	connection_coord: Vector2Int,
	processed:        bool,
}


f_cost :: proc(node: Node) -> f32 {
	return node.g + node.h
}


neighbours: [4]Vector2Int : {{1, 0}, {0, -1}, {0, 1}, {-1, 0}}


find_path :: proc(
	start_pos: Vector2Int,
	end: Vector2Int,
	has_temp_block := false,
	temp_block_pos: Vector2Int = {},
) -> [dynamic]Vector2Int {
	nodes: map[Vector2Int]Node = make(map[Vector2Int]Node, temp_allocator())

	{
		start := Vector2{auto_cast start_pos.x, auto_cast start_pos.y} * TILE_SIZE
		end := Vector2{auto_cast end.x, auto_cast end.y} * TILE_SIZE


		for tile in game.tiles {
			node: Node
			node.walkable = tile.walkable
			node.position = tile.grid_position
			node.g = 100000000
			node.travel_g_cost = auto_cast get_card_type_g_cost(tile.card_type)
			node.processed = false

			for p in game.entities {
				if p.grid_position == node.position && get_card_type_g_cost(p.card_type) > 0{
					node.walkable = false
				}
			}


			for t in game.trees {
    			if world_to_grid_pos(t.position) == node.position {
    				node.walkable = false
    			}
					}

			if game.selected_card_index > -1 {
			    card_type:= game.hand[game.selected_card_index].type
				if node.position == game.selected_card_grid_placement_position && get_card_type_g_cost(card_type) > 0{
					node.walkable = false
				}
			}

			if has_temp_block {
				if node.position == temp_block_pos {
					node.walkable = false
				}
			}

			nodes[tile.grid_position] = node
		}
	}


	if end in nodes {
		if !nodes[end].walkable {
			return nil
		}
	} else {
		return nil
	}

	to_search: [dynamic]Vector2Int = make([dynamic]Vector2Int, 1, temp_allocator())
	append(&to_search, start_pos)
	processed: [dynamic]Vector2Int
	processed.allocator = temp_allocator()
	// Initialize the start node's g cost
	start: ^Node = &nodes[start_pos]
	start.g = 0


	for len(to_search) > 0 {
		current_pos := to_search[0]
		current_index := 0

		// Find node with lowest f_cost
		for i := 0; i < len(to_search); i += 1 {
			pos := to_search[i]
			if f_cost(nodes[pos]) < f_cost(nodes[current_pos]) ||
			   f_cost(nodes[pos]) == f_cost(nodes[current_pos]) &&
				   nodes[pos].h < nodes[current_pos].h {
				current_pos = pos
				current_index = i
			}
		}

		append(&processed, current_pos)
		node := &nodes[current_pos]
		node.processed = true
		ordered_remove(&to_search, current_index)

		if current_pos == end {
			current_path_tile_pos := current_pos
			path: [dynamic]Vector2Int
			// path.allocator = temp_allocator()
			// let the call handle the mem
			for current_path_tile_pos != start.position {


				current := nodes[current_path_tile_pos]
				if !current.processed || current.connection_coord == current_path_tile_pos {
					log("NOT PROCESSED")
					return nil
				}

				append(&path, current.position)
				current_path_tile_pos = current.connection_coord
			}
			// Add start node to complete the path
			//
			return path
		}

		for neighbour_pos in neighbours {
			neighbour_position := neighbour_pos + current_pos

			if !(neighbour_position in nodes) || !nodes[neighbour_position].walkable {
				continue
			}

			dx := neighbour_position.x - current_pos.x
			dy := neighbour_position.y - current_pos.y


			already_processed := false
			for p in processed {
				if p == neighbour_position {
					already_processed = true
					break
				}
			}

			if already_processed {
				continue
			}

			cost_to_neighbour :=
				nodes[current_pos].g +
				manhattan_dist(current_pos, neighbour_position) +
				nodes[current_pos].travel_g_cost

			in_search := false
			for search in to_search {
				if search == neighbour_position {
					in_search = true
					break
				}
			}

			if !in_search || cost_to_neighbour < nodes[neighbour_position].g {
				neighbour: ^Node = &nodes[neighbour_position]

				neighbour.g = cost_to_neighbour
				neighbour.connection_coord = current_pos

				if !in_search {
					neighbour.h = manhattan_dist(neighbour_position, end)
					append(&to_search, neighbour_position)
				}
			}
		}
	}
	return nil
}
