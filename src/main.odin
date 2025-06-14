package main


/*******************************************************************************************
*
*   raylib - classic game: tetroid
*
*   Sample game developed by Marc Palau and Ramon Santamaria
*
*   This game has been created using raylib v1.3 (www.raylib.com)
*   raylib is licensed under an unmodified zlib/libpng license (View raylib.h for details)
*
*  Translation from https://github.com/raysan5/raylib-games/blob/master/classics/src/tetris.c to Odin
*
*   Copyright (c) 2015 Ramon Santamaria (@raysan5)
*   Copyright (c) 2021 Ginger Bill
*
********************************************************************************************/

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:math/rand"
import "core:mem"
import rl "vendor:raylib"

Rect :: rl.Rectangle
atlas: rl.Texture2D
log :: fmt.println


SCREEN_WIDTH :: 1280
SCREEN_HEIGHT :: 720
PIXEL_WINDOW_HEIGHT :: SCREEN_HEIGHT
PIXEL_WINDOW_WIDTH :: SCREEN_WIDTH

GRID_SIZE_X: int : 16
GRID_SIZE_Y: int : 13

CARD_SCALE: f32 = 2.5
CARD_WIDTH: f32 = 64 * CARD_SCALE
CARD_HEIGHT: f32 = 78 * CARD_SCALE
CARD_SPACING: f32 = 1.5
temp_allocator :: proc() -> mem.Allocator {
	return context.temp_allocator
}

AppState :: enum {
	splash_logo,
	splash_fmod,
	main_menu,
	game,
}

InGameState :: enum {
	CardSelect,
	Shop,
	InBattle,
}


PopupText :: struct {
	position: Vector2,
	value:    cstring,
	alpha:    int,
	active:   bool,
	color:    rl.Color,
}


SpriteParticle :: struct {
	position:      Vector2,
	active:        bool,
	atlas_anim:    Animation_Name,
	current_frame: Texture_Name,
	timer:         f32,
}


PlayerProjectile :: struct {
	active:            bool,
	position:          Vector2,
	rotation_z:        f32,
	velocity:          Vector2,
	distance_traveled: f32,
}


Tree :: struct {
	position: Vector2,
}

DOT_COUNTER_TIME :: 0.8
INITIAL_DRAW_CARD_COST :: 1

Game :: struct {
	world_time_elapsed:                      f32,
	ticks:                                   u64,
	camera:                                  rl.Camera2D,

	// game state
	in_game_state:                           InGameState,
	app_state:                               AppState,
	hand:                                    [dynamic]Card,
	tiles:                                   [GRID_SIZE_X * GRID_SIZE_Y]Tile,
	entities:                                [dynamic]Entity,
	player_base_grid_position:               Vector2Int,
	player_health:                           int,
	draw_card_cost:                          int,
	reroll_shop_cost:                        int,
	popup_text:                              [dynamic]PopupText,
	sprite_particle:                         [dynamic]SpriteParticle,
	player_projectiles:                      [dynamic]PlayerProjectile,
	permanent_deck:                          [dynamic]CardType,
	in_run_deck:                             [dynamic]CardType,
	discard_pile:                            [dynamic]CardType,
	trees:                                   [dynamic]Tree,
	particle_emitters:                       [dynamic]ParticleEmitter,

	// intro stuff
	game_by_buffer:                          string,
	// Shop
	shop_items:                              [5]ShopItem,

	// card stuff
	gold:                                    int,
	selected_card_index:                     int,
	hover_card_index:                        int,
	selected_entity_index:                   int,
	selected_card_grid_placement_position:   Vector2Int,
	selected_entity_grid_placement_position: Vector2Int,
	can_place_selected_card:                 bool,
	can_place_selected_entity:               bool,

	// run stats *UPGRADABLE*
	cards_per_hand:                          int,

	// Round/run stuff
	round:                                   int,
	// Enemy stuff
	enemy_paths:                             [dynamic]NodePath,

	// UX
	using ux_state:                          struct {
		ux_alpha:      f32,
		ux_y_offset:   f32,
		ux_anim_state: enum {
			fade_in,
			hold,
			fade_out,
		},
		hold_end_time: f64,
	},
}
game: Game


init_time: f64
seconds_since_init :: proc() -> f64 {
	if init_time == 0 {
		log("invalid time - init_time not set")
		return 0
	}
	return rl.GetTime() - init_time
}
app_now :: seconds_since_init

// Initialize the timer (call this once after InitWindow)
init_timer :: proc() {
	init_time = rl.GetTime()
}

main :: proc() {
	flags: rl.ConfigFlags = {.WINDOW_RESIZABLE}
	rl.SetConfigFlags(flags)
	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Game")

	rl.SetExitKey(.KEY_NULL)
	defer rl.CloseWindow()

	init_game()
	rl.SetTargetFPS(240)

	size := get_pixel_screen_size()

	target_pos := (Vector2{auto_cast GRID_SIZE_X, auto_cast GRID_SIZE_Y} * TILE_SIZE) / 2
	game.camera = rl.Camera2D {
		zoom   = 4.0,
		target = target_pos + TILE_SIZE,
		offset = size / 2,
	}

	init_gfx()
	init_timer()

	game_by_buffer := "A game by louidev.."
	dot_count := 0
	dot_counter: f32 = DOT_COUNTER_TIME
	game.app_state = .splash_logo
	exit := false
	for !rl.WindowShouldClose() && !exit {
		dt: f32 = rl.GetFrameTime()
		app_dt: f32 = dt
		ticks_per_second = u64(1.0 / dt)
		ticks_per_second = clamp(ticks_per_second, 60, 240)
		defer game.ticks += 1
		defer game.world_time_elapsed += app_dt

		switch game.app_state {
		case .game:
			update_game(dt)
		case .main_menu:
			{
				switch game.ux_anim_state {
				case .fade_in:
					if game.ux_alpha == 0.0 {
						game.ux_alpha = 1.0
					}
					reached := animate_to_target_f32(
						&game.ux_alpha,
						0.0,
						dt,
						rate = 1.0,
						good_enough = 0.05,
					)
					if reached {
						game.ux_anim_state = .hold
					}
				case .hold:
					{

					}


				case .fade_out:
					reached := animate_to_target_f32(
						&game.ux_alpha,
						1.0,
						dt,
						rate = 5.0,
						good_enough = 0.05,
					)
					if reached {
						game.ux_state = {}
						game.app_state = .game
					}
				}

				alpha: f32 = 255 * game.ux_alpha
				color: rl.Color = {0, 0, 0, auto_cast alpha}

				screen_width := f32(rl.GetScreenWidth())
				screen_height := f32(rl.GetScreenHeight())
				position: Vector2 = {screen_width * 0.5, screen_height * 0.5}
				button_size: Vector2 = {60 * 4, 24 * 4}
				padding: f32 = 5
				start_btn_pos := position
				start_btn_pos.y += button_size.y + padding
				if image_button(start_btn_pos, "Start Game", 32, 1) {
					game.ux_state.ux_anim_state = .fade_out
				}

				start_btn_pos.y += button_size.y + padding

				if image_button(start_btn_pos, "Options", 32, 1) {
					game.app_state = .game
				}

				start_btn_pos.y += button_size.y + padding

				if image_button(start_btn_pos, "Exit", 32, 1) {
					exit = true
				}


				draw_rect(position, {screen_width, screen_height}, color)

			}
		case .splash_fmod:
			{
				set_z_layer(.ui)
				draw_frame.layer[.ui].camera = {
					zoom = 1.0,
				}
				screen_width := f32(rl.GetScreenWidth())
				screen_height := f32(rl.GetScreenHeight())
				position: Vector2 = {screen_width * 0.5, screen_height * 0.5}


				color := splash_screen_logic(dt, .main_menu, DOT_COUNTER_TIME * 4)

				draw_sprite(
					{screen_width * 0.5, screen_height * 0.5},
					.Fmod_Logo,
					atlas_textures[.Fmod_Logo].document_size,
					color,
				)

			}
		case .splash_logo:
			{
				set_z_layer(.ui)
				draw_frame.layer[.ui].camera = {
					zoom = 1.0,
				}
				screen_width := f32(rl.GetScreenWidth())
				screen_height := f32(rl.GetScreenHeight())
				position: Vector2 = {screen_width * 0.5, screen_height * 0.5}
				str: [dynamic]u8
				for i := 0; i < dot_count; i += 1 {
					append_string(&str, ".")
				}
				defer delete(str)

				if rl.IsKeyPressed(.SPACE) {
					game.app_state = .splash_fmod
				}

				switch game.ux_anim_state {
				case .fade_in:
					reached := animate_to_target_f32(
						&game.ux_alpha,
						1.0,
						dt,
						rate = 3.0,
						good_enough = 0.05,
					)
					if reached {
						game.ux_anim_state = .hold
						game.hold_end_time = app_now() + DOT_COUNTER_TIME * 4
					}
				case .hold:
					dot_counter -= dt

					if app_now() >= game.hold_end_time {
						game.ux_anim_state = .fade_out
					}


					if dot_counter <= 0 {
						dot_counter = DOT_COUNTER_TIME
						if dot_count < 3 {
							dot_count += 1
						}
					}


				case .fade_out:
					reached := animate_to_target_f32(
						&game.ux_alpha,
						0.0,
						dt,
						rate = 5.0,
						good_enough = 0.05,
					)
					if reached {
						game.ux_state = {}
						game.app_state = .splash_fmod
					}
				}

				alpha: f32 = 255 * game.ux_alpha
				color: rl.Color = {255, 255, 255, auto_cast alpha}

				draw_text(
					position,
					to_c_string(fmt.tprintf("A game by louidev%s", str)),
					40,
					color,
				)
				draw_text(position + {0, -60}, "Early demo v0.1", 30, color)
			}


		}


		render_frame()
		inputs = {}
	}
}


init_game :: proc() {
	atlas = rl.LoadTexture("assets/atlas.png")


	for x := 0; x < GRID_SIZE_X; x += 1 {
		for y := 0; y < GRID_SIZE_Y; y += 1 {
			tile := &game.tiles[y * GRID_SIZE_X + x]
			tile.position = grid_to_world_pos({x, y})
			tile.grid_position = {x, y}
			tile.walkable = true

		}
	}

	game.player_base_grid_position = {GRID_SIZE_X / 2, GRID_SIZE_Y / 2}
	game.cards_per_hand = 5
	game.player_health = 10
	game.selected_card_index = -1
	game.hover_card_index = -1
	game.selected_entity_index = -1
	game.draw_card_cost = 1

	for i := 0; i < 40; i += 1 {
		random_card := CardType(rand.int_max(len(CardType) - 1) + 1)

		append(&game.permanent_deck, random_card)
	}


	tree_count := rand.int_max(25) + 15


	occupied_positions: map[Vector2Int]bool
	defer delete(occupied_positions)
	occupied_positions[game.player_base_grid_position + {1, 0}] = true
	occupied_positions[game.player_base_grid_position] = true

	for i := 0; i < tree_count; i += 1 {
		tree: Tree


		grid_pos := Vector2Int {
			rand.int_max(GRID_SIZE_X - 2) + 1,
			rand.int_max(GRID_SIZE_Y - 2) + 1,
		}


		if !occupied_positions[grid_pos] {
			tree.position = grid_to_world_pos(grid_pos)
			occupied_positions[grid_pos] = true
			append(&game.trees, tree)
		}

	}


	populate_deck()
	on_round_start()

}


ticks_per_second: u64
update_game :: proc(dt: f32) {


	if rl.IsWindowResized() {
		on_resize_gfx()
	}

	// @GAME_UI @UI
	set_z_layer(.ui)
	draw_frame.layer[.ui].camera = {
		zoom = 1.0,
	}

	screen_width := f32(rl.GetScreenWidth())
	screen_height := f32(rl.GetScreenHeight())


	if game.in_game_state == .Shop {
		if IsKeyReleased(.ESCAPE) {
			game.in_game_state = .CardSelect
			capture_key_released(.ESCAPE)
		}

		draw_rect(
			{screen_width * 0.5, screen_height * 0.5},
			{screen_width, screen_height},
			{0, 0, 0, 100},
		)

		shop_item_width: f32 = 200
		padding: f32 = 10
		item_position := Vector2 {
			screen_width * 0.5 -
			((shop_item_width + padding) * len(game.shop_items) * 0.5) -
			0.5 * (shop_item_width + padding),
			screen_height * 0.5,
		}


		for &item in game.shop_items {
			item_position.x += shop_item_width + padding

			draw_text(item_position - {0, 80}, get_shop_item_name(item))

			draw_rect(item_position, {84, 84}, rl.BLACK)
			draw_rect(item_position, {70, 70}, rl.WHITE)
			draw_sprite(item_position, get_shop_item_texture_name(item), {64, 64})

			if draw_button(
				item_position + {0, 100},
				{shop_item_width - padding * 2, 70},
				to_c_string(fmt.tprintf("Buy $:%d", item.cost)),
				24,
				game.gold < item.cost || item.purchased,
				false,
				6.0,
			) {
				item.purchased = true
			}
		}


		if draw_button(
			{screen_width * 0.5, screen_height * 0.5 + 250},
			{160, 80},
			to_c_string(fmt.tprintf("Reroll $:%d", game.reroll_shop_cost)),
			14,
			game.gold < game.reroll_shop_cost,
			false,
			4.0,
		) {
			game.reroll_shop_cost += 1
			generate_shop_items()
		}
	}

	// @UI @Card select
	//
	//
	//

	if game.hover_card_index > -1 || game.selected_card_index > -1 {

		card_type :=
			(game.hand[game.hover_card_index > -1 ? game.hover_card_index : game.selected_card_index]).type
		draw_text(
			{10, screen_height - 200},
			get_card_description(card_type),
			24,
			rl.WHITE,
			.top_left,
		)
	}


	draw_rect({0, screen_height}, {screen_width, 80}, rl.BLACK, .top_left)
	if game.in_game_state != .InBattle &&
	   draw_button(
		   {125, screen_height - 40},
		   {150, 50},
		   game.in_game_state == .Shop ? "Exit" : "Shop",
		   20,
		   game.in_game_state == .InBattle,
		   false,
		   6.0,
	   ) {
		game.in_game_state = game.in_game_state == .Shop ? .CardSelect : .Shop
		game.ux_state = {}

	}

	if game.in_game_state != .InBattle &&
	   draw_button(
		   {screen_width - 150, screen_height - 40},
		   {200, 50},
		   "Start Battle",
		   16,
		   game.in_game_state != .CardSelect,
		   game.in_game_state == .InBattle,
		   6.0,
	   ) {

		game.in_game_state = .InBattle
		game.ux_state = {}
	}

	if game.in_game_state != .InBattle &&
	   draw_button(
		   {screen_width - 380, screen_height - 40},
		   {200, 50},
		   to_c_string(fmt.tprintf("Draw card $%d", game.draw_card_cost)),
		   16,
		   game.in_game_state != .CardSelect || game.gold < game.draw_card_cost,
		   false,
		   6.0,
	   ) {

		if len(game.in_run_deck) == 0 {
			shuffle_deck()
			assert(len(game.in_run_deck) > 0)
		}


		draw_card()


		game.draw_card_cost += 1
		game.gold -= game.draw_card_cost

	}


	{


		base_pos_y: f32 = 40
		padding: f32 = 8
		draw_sprite(
			{40, base_pos_y},
			.Ui,
			{64, 64},
			rl.WHITE,
			.center_center,
			get_sprite_rect(.Ui, {0, 1}, 16),
		)

		draw_text(
			{100, base_pos_y},
			to_c_string(fmt.tprintf("%d", game.player_health)),
			32,
			rl.WHITE,
			.center_center,
			4.0,
		)

		base_pos_y += 70

		draw_sprite(
			{40, base_pos_y},
			.Ui,
			{64, 64},
			rl.WHITE,
			.center_center,
			get_sprite_rect(.Ui, {0, 0}, 16),
		)
		draw_text(
			{100, base_pos_y},
			to_c_string(fmt.tprintf("$%d", game.gold)),
			32,
			rl.WHITE,
			.center_center,
			4.0,
		)


	}


	set_z_layer(.background)

	x := f32(int(rl.IsKeyDown(.D)) - int(rl.IsKeyDown(.A)))
	y := f32(int(rl.IsKeyDown(.S)) - int(rl.IsKeyDown(.W)))


	if game.in_game_state != .Shop {
		game.camera.target += {x, y} * dt * 120
	}


	// rl.DrawFPS(0, 0)

	mouse_inside_tile := false
	mouse_tile_grid_pos: Vector2Int

	mouse_world_position := rl.GetScreenToWorld2D(get_mouse_position(), game.camera)

	// @TILES
	for x := 0; x < GRID_SIZE_X; x += 1 {
		for y := 0; y < GRID_SIZE_Y; y += 1 {
			tile := game.tiles[y * GRID_SIZE_X + x]
			set_z_layer(.background)
			draw_sprite(tile.position, .Tiles, {TILE_SIZE, TILE_SIZE})

			if aabb_center_contains(
				   tile.position,
				   {TILE_SIZE + 3, TILE_SIZE + 3},
				   mouse_world_position,
			   ) &&
			   game.in_game_state != .Shop {
				mouse_inside_tile = true
				mouse_tile_grid_pos = {x, y}
			}


		}
	}

	// @entities
	{
		for i := 0; i < len(game.entities); i += 1 {

			ent := &game.entities[i]
			ent_attack_style := get_attack_style(ent.card_type)
			if ent.card_type != .nil && ent.active {
				ent.attack_cooldown_time = math.max(0, ent.attack_cooldown_time - dt)
				if ent.ent_type == .active &&
				   game.in_game_state == .InBattle &&
				   ent.attack_cooldown_time <= 0 {
					loop: for pos in get_attack_positions(
						ent.grid_position,
						ent.range,
						ent.card_type,
					) {
						grid_pos := ent.grid_position + pos

						for &path in game.enemy_paths {
							for &enemy in path.enemies {
								if enemy.active {

									switch ent_attack_style {
									case .Meele:
										{
											if aabb_center_contains(
												enemy.position,
												{10, 10},
												grid_to_world_pos(ent.grid_position + pos),
											) {
												ent.attack_cooldown_time = ATTACK_COOLDOWN

												ent.attack_target_direction = linalg.normalize(
													enemy.position - ent.position,
												)
												ent.animation_state = .Attacking
												ent.flipped = enemy.position.x < ent.position.x


												damage_enemy(&enemy, ent.attack_amount)

												break loop
											}
										}
									case .Ranged:
										{
											if aabb_center_contains(
												enemy.position,
												{10, 10},
												grid_to_world_pos(ent.grid_position + pos),
											) {
												ent.attack_cooldown_time = ATTACK_COOLDOWN
												projectile: PlayerProjectile
												projectile.position = ent.position
												projectile.active = true

												direction := linalg.normalize(
													enemy.position - ent.position,
												)

												projectile.velocity = direction * 100
												angle_rad := linalg.atan2(direction.y, direction.x)

												// Convert radians to degrees if needed
												angle_deg := angle_rad * (180 / math.PI)
												projectile.rotation_z = angle_deg


												append(&game.player_projectiles, projectile)
												break loop
											}

										}
									}


								}
							}

						}
					}
				}

				color := rl.WHITE

				scale: Vector2 = {1, 1}

				if ent.movable && ent.animation_state != .Attacking {
					scale.x -= sine_breathe_alpha(game.world_time_elapsed) * 0.1
					scale.x += cos_breathe_alpha(game.world_time_elapsed) * 0.1
					scale.y += sine_breathe_alpha(game.world_time_elapsed) * 0.1
					scale.y -= cos_breathe_alpha(game.world_time_elapsed) * 0.1
				}

				if game.in_game_state == .InBattle {
					switch ent.animation_state {
					case .Attacking:
						is_target_axis_x := ent.position.x != ent.attack_target_direction.x
						if is_target_axis_x {
							if animate_to_target_f32(
								&ent.position.x,
								ent.position.x + ent.attack_target_direction.x * 10,
								dt,
								10.0,
								30,
							) {
								ent.animation_state = .Idle
							}
						} else {
							if animate_to_target_f32(
								&ent.position.y,
								ent.position.x + ent.attack_target_direction.y * 10,
								dt,
								10.0,
								30,
							) {
								ent.animation_state = .Idle
							}
						}
					case .Idle:
						target_pos := grid_to_world_pos(ent.grid_position)
						if ent.position != target_pos {
							animate_v2_to_target(&ent.position, target_pos, dt, 10.0)
						}


					}
				}


				if game.in_game_state == .CardSelect && ent.movable {
					hover := false
					if mouse_tile_grid_pos == ent.grid_position {
						hover = true
						if IsMouseButtonPressed(.LEFT) {
							capture_mouse_pressed(.LEFT)
							game.selected_entity_index = i
						}
					}

					if game.selected_entity_index == i {
						ent.position = grid_to_world_pos(mouse_tile_grid_pos) - {0, 2.0}


						new_tile := &game.tiles[mouse_tile_grid_pos.y * GRID_SIZE_X + mouse_tile_grid_pos.x]
						can_place :=
							new_tile.card_type == CardType.nil || new_tile.card_type == nil


						if game.selected_entity_grid_placement_position != mouse_tile_grid_pos {
							game.selected_entity_grid_placement_position = mouse_tile_grid_pos
							game.can_place_selected_entity = true
							for &path in game.enemy_paths {
								temp_path := find_path(
									game.player_base_grid_position,
									path.start_position,
									true,
									mouse_tile_grid_pos,
								)
								if temp_path == nil || len(temp_path) == 0 {
									log("CANT PLACE")
									game.can_place_selected_entity = false
								} else {
									clear(&path.path)
									path.path = temp_path
								}
							}
						}

						if !game.can_place_selected_entity || !can_place {
							if ent.grid_position != world_to_grid_pos(ent.position) {
								color = rl.RED
							}
						}

						if IsMouseButtonReleased(.LEFT) {
							capture_mouse_released(.LEFT)

							game.selected_entity_index = -1

							if game.can_place_selected_entity && can_place {
								// @TODO VALIDATE
								old_tile := &game.tiles[ent.grid_position.y * GRID_SIZE_X + ent.grid_position.x]

								old_tile.card_type = .nil
								ent.grid_position = mouse_tile_grid_pos
								ent.position = grid_to_world_pos(ent.grid_position)
								new_tile.card_type = ent.card_type
							}

						}
					}


				}


				set_z_layer(.game_play)
				image_id := get_card_image_id(ent.card_type)

				draw_sprite(
					ent.position - get_entity_tile_placement_pos(ent.card_type),
					image_id,
					get_card_entity_size(ent.card_type),
					color,
					.center_center,
					{},
					scale,
					ent.flipped,
				)
			}
		}
	}


	// @trees
	//
	{


		for tree in game.trees {
			draw_sprite(tree.position - {0, 3}, .Tree, {12, 16})
		}
	}


	// @arrow_paths_render
	{
		for path in game.enemy_paths {

			for i := 0; i < len(path.path); i += 1 {

				prev := i > 0 ? path.path[i - 1] : path.path[0]
				curr := path.path[i]
				next := i < len(path.path) - 1 ? path.path[i + 1] : path.path[i]


				// calculate the direction
				next_direction := vector_to_dir(curr, next)
				direction := vector_to_dir(prev, curr, next_direction)
				tile_type := ArrowTileType.Straight
				if direction != next_direction {
					tile_type = .Curved
				}


				sprite_index: Vector2Int


				switch direction {
				case .East:
					if tile_type == .Straight {
						sprite_index = {2, 0}
					} else if tile_type == .Curved {
						if next_direction == .South {
							sprite_index = {2, 1}
						} else {
							sprite_index = {2, 2}
						}
					}

				case .North:
					if tile_type == .Straight {
						sprite_index = {0, 1}
					} else if tile_type == .Curved {
						if next_direction == .East {
							sprite_index = {1, 1}
						} else {
							sprite_index = {2, 1}
						}
					}
				case .South:
					if tile_type == .Straight {
						sprite_index = {0, 1}
					} else if tile_type == .Curved {
						if next_direction == .East {
							sprite_index = {1, 2}
						} else {
							sprite_index = {2, 2}
						}
					}
				case .West:
					if tile_type == .Straight {
						sprite_index = {2, 0}
					} else if tile_type == .Curved {
						if next_direction == .South {
							sprite_index = {1, 1}
						} else {
							sprite_index = {1, 2}
						}
					}
				}

				if i == len(path.path) - 1 {
					switch direction {
					case .East:
						sprite_index = {3, 0}
					case .West:
						sprite_index = {1, 0}
					case .North:
						sprite_index = {0, 0}
					case .South:
						sprite_index = {0, 2}
					}
				}

				set_z_layer(.game_play)


				rect := get_sprite_rect(.Path_Arrow, sprite_index, 16)

				draw_sprite(
					grid_to_world_pos(path.path[i]),
					.Path_Arrow,
					{16, 16},
					game.in_game_state == .InBattle ? {255, 255, 255, 100} : {255, 255, 255, 200},
					.center_center,
					rect,
				)

			}
		}
	}

	// @enemies
	if game.in_game_state == .InBattle {
		for &path in game.enemy_paths {
			spawn_enemy_in_queue := false

			for &enemy in path.enemies {
				if !spawn_enemy_in_queue && !enemy.spawned {
					spawn_enemy_in_queue = true
					enemy.enemy_spawn_timer = math.max(0, enemy.enemy_spawn_timer - dt)
					if enemy.enemy_spawn_timer <= 0 {
						enemy.active = true
						enemy.spawned = true
						enemy.position = grid_to_world_pos(
							path.path[0] + cardinal_direction_to_vector(path.start_direction),
						)
						enemy.next_target_path_index = 0
						enemy.target_position = grid_to_world_pos(
							path.path[enemy.next_target_path_index],
						)
						enemy.grid_position =
							path.path[0] + cardinal_direction_to_vector(path.start_direction)

						enemy.flipped = path.start_direction == .East
					}
				}

				if enemy.health <= 0 {
					enemy.active = false
				}

				if !enemy.active {
					continue
				}
				enemy.flash_timer = math.max(0, enemy.flash_timer - dt)
				// @projectile dmg enemy
				projectile_loop: for &projetile in game.player_projectiles {
					if aabb_center_contains(enemy.position, {10, 10}, projetile.position) {
						projetile.active = false
						damage_enemy(&enemy, 1)
						break projectile_loop
					}
				}


				dx := math.sign((enemy.target_position.x - enemy.position.x))

				dy := math.sign((enemy.target_position.y - enemy.position.y))

				enemy.position.x += dx * dt * enemy.speed
				enemy.position.y += dy * dt * enemy.speed
				// animate_v2_to_target(&enemy.position, enemy.target_position, dt, 10.0)

				close :=
					almost_equals(enemy.position.x, enemy.target_position.x, 0.4) &&
					almost_equals(enemy.position.y, enemy.target_position.y, 0.4)

				if close && enemy.active {
					if enemy.next_target_path_index + 1 < len(path.path) {
						enemy.next_target_path_index += 1
						facing_dir := vector_to_dir(
							path.path[enemy.next_target_path_index - 1],
							path.path[enemy.next_target_path_index],
						)
						if facing_dir == .West || facing_dir == .East {
							enemy.flipped = facing_dir == .West
						}

						enemy.target_position = grid_to_world_pos(
							path.path[enemy.next_target_path_index],
						)
						enemy.grid_position = path.path[enemy.next_target_path_index]

					} else {
						enemy.grid_position = game.player_base_grid_position
						enemy.target_position = grid_to_world_pos(game.player_base_grid_position)

						close :=
							almost_equals(enemy.position.x, enemy.target_position.x, 0.4) &&
							almost_equals(enemy.position.y, enemy.target_position.y, 0.4)

						if close {
							enemy.active = false
							enemy.health = 0
							game.player_health -= 1
							create_player_dmg_popup(1, enemy.position)
						}
					}
				}


				position := enemy.position
				scale: Vector2 = {1, 1}
				scale.x -= sine_breathe_alpha(game.world_time_elapsed) * 0.05
				scale.x += cos_breathe_alpha(game.world_time_elapsed) * 0.05
				scale.y += sine_breathe_alpha(game.world_time_elapsed) * 0.05
				scale.y -= cos_breathe_alpha(game.world_time_elapsed) * 0.05


				position.y += sine_breathe_alpha(game.world_time_elapsed) * enemy.speed * 0.1
				position.y -= cos_breathe_alpha(game.world_time_elapsed) * enemy.speed * 0.1


				rotation :=
					cos_breathe_alpha(game.world_time_elapsed * 0.5) * 0.05 -
					sine_breathe_alpha(game.world_time_elapsed * 0.5) * 0.05

				draw_call_pointer := draw_sprite(
					position,
					.Enemies,
					{16, 16},
					rl.WHITE,
					.center_center,
					{},
					scale,
					enemy.flipped,
					0,
					rotation,
				)

				draw_call_pointer.shader = .flash_hit

				enemy.flash_value = enemy.flash_timer > 0 ? 1 : 0
				enemy.flash_color = {1, 1, 1}

				set_shader_value(draw_call_pointer, "flashAmount", &enemy.flash_value, .FLOAT)
				set_shader_value(draw_call_pointer, "flashColor", &enemy.flash_color, .VEC3)


				if enemy.health < enemy.max_health {
					bar_size: Vector2 = {18, 2}
					draw_rect(enemy.position - {0, 10}, bar_size + {2, 2}, rl.BLACK)
					draw_rect(enemy.position - {0, 10}, bar_size, rl.WHITE)
					draw_rect(
						enemy.position - {bar_size.x * 0.5, 10},
						{bar_size.x * f32(enemy.health) / f32(enemy.max_health), bar_size.y},
						rl.RED,
						.center_left,
					)
				}
			}
		}

		// @END OF ROUND
		// @end_of_round
		still_alive := false
		for &path in game.enemy_paths {
			spawn_enemy_in_queue := false

			for &enemy in path.enemies {
				if enemy.health > 0 {
					still_alive = true
					break
				}
			}

			if still_alive {
				break
			}
		}
		if !still_alive {
			for ent in game.entities {
				additional_money := get_money_value_end_of_round(ent.card_type)
				if additional_money > 0 {
					game.gold += additional_money
					create_money_popup(additional_money, ent.position)

				}
			}


			on_round_start()
			game.in_game_state = .CardSelect
			game.ux_state = {}
		}
	}


	ATTACK_COOLDOWN: f32 : 0.5


	// @base
	{
		draw_sprite(grid_to_world_pos(game.player_base_grid_position) - {0, 3}, .Base, {16, 16})
	}


	{ 	// @projectiles @player_projectiles
		for &projectile in game.player_projectiles {


			if !projectile.active {
				continue
			}

			if projectile.distance_traveled > 500 {
				projectile.active = false
			}

			new_dist := projectile.velocity * dt
			projectile.position += new_dist
			projectile.distance_traveled += linalg.length(new_dist)


			draw_sprite(
				projectile.position,
				.Projectile_Arrow,
				{26, 9} * 0.35,
				rl.WHITE,
				.center_center,
				{},
				{1, 1},
				false,
				0,
				projectile.rotation_z,
			)
		}
	}


	if mouse_inside_tile {
		set_z_layer(.background)
		draw_sprite(grid_to_world_pos(mouse_tile_grid_pos), .Selection_Cursor, {16, 16})
	}

	switch game.in_game_state {

	case .CardSelect:
		using game
		switch game.ux_anim_state {

		case .fade_in:
			reached := animate_to_target_f32(&ux_y_offset, 0, dt, rate = 5.0, good_enough = 0.05)
			if reached {
				ux_anim_state = .hold
			}

		case .hold:
			offset: f32 = 0
			if game.selected_card_index > -1 {
				offset = -120

			}

			animate_to_target_f32(&ux_y_offset, offset, dt, rate = 5.0, good_enough = 0.05)
		case .fade_out:

		}
	case .InBattle, .Shop:
		using game
		switch game.ux_anim_state {

		case .fade_in:
			reached := animate_to_target_f32(
				&ux_y_offset,
				-240,
				dt,
				rate = 5.0,
				good_enough = 0.05,
			)
			if reached {
				ux_anim_state = .hold
			}

		case .hold:


		case .fade_out:

		}

	}

	// @particles

	{
		for &p in game.sprite_particle {


			p.timer -= dt


			if p.timer <= 0 {
				p.current_frame = Texture_Name(int(p.current_frame) + 1)
				anim := atlas_animations[p.atlas_anim]

				if p.current_frame > anim.last_frame {
					p.active = false
				} else {
					p.timer = atlas_textures[p.current_frame].duration
				}


			}


			if !p.active {
				continue
			}

			draw_sprite(p.position, p.current_frame, atlas_textures[p.current_frame].document_size)
		}
	}

	update_and_render_particles(dt)


	// @POPUP TEXT
	{
		set_z_layer(.game_play)
		for &text in game.popup_text {
			color := text.color
			if text.alpha <= 0 && text.active {
				text.alpha = 0
				text.active = false
				delete(text.value)
				continue
			}

			color.a = auto_cast math.clamp(text.alpha + 100, 50, 255)
			text.position.y -= 15 * dt
			text.alpha -= 2

			draw_text(text.position, text.value, 8, color, .center_center, 1.0)
		}


	}

	// @HAND
	// @CARDS
	// calculate position for cards
	{
		set_z_layer(.cards)


		camera := rl.Camera2D {
			zoom = 1.0,
			// offset = {screen_width / 2, screen_height / 2},
			// target = {screen_width / 4, -100},
		}

		draw_frame.layer[.cards].camera = camera

		length: f32 = auto_cast len(game.hand)


		mouse_world_position := rl.GetScreenToWorld2D(get_card_mouse_position(), camera)
		w, h: f32 = SCREEN_WIDTH, SCREEN_HEIGHT


		total_width: f32 = (CARD_WIDTH * 0.85 * length)
		starting_pos_x: f32 = ((w - total_width) / 2) + CARD_WIDTH / 2

		x: f32 = 0.0
		game.hover_card_index = -1

		for i := 0; i < len(game.hand); i += 1 {
			card := &game.hand[i]


			defer x += CARD_WIDTH * .85
			target_pos: Vector2 =
				{(starting_pos_x + x), (h / camera.zoom) - CARD_HEIGHT / 2 + 60} -
				(game.selected_card_index == i ? {0, 100} : {0, game.ux_state.ux_y_offset + 90})


			hover := false
			card.hover_cooldown = math.max(0, card.hover_cooldown - dt)
			position := card.position
			ratio := len(game.hand) == 1 ? 0.5 : f32(i) / f32(len(game.hand) - 1)

			// amount the cards are effected by faning in the y pos
			fan_y_amount := f32(2.0 * f32(ratio) * (1.0 - f32(ratio))) * 80
			position.y -= fan_y_amount

			if game.in_game_state == .CardSelect &&
			   aabb_center_contains(
				   position,
				   card.last_frame_state != .None ? {CARD_WIDTH, CARD_HEIGHT} : {CARD_WIDTH, CARD_HEIGHT} * 0.8,
				   mouse_world_position,
			   ) {

				if game.hover_card_index == -1 {
					hover = true
					game.hover_card_index = i
				} else {
					other_card := game.hand[game.hover_card_index]
					if linalg.distance(other_card.position, mouse_world_position) >
					   linalg.distance(other_card.position, mouse_world_position) {
						hover = true
						game.hover_card_index = i
					}
				}


			}

			if hover {
				card.last_frame_state = .Hover
			}

			if hover && IsMouseButtonPressed(.LEFT) && game.gold >= card.cost {
				capture_mouse_pressed(.LEFT)
				game.selected_card_index = i
				game.selected_card_grid_placement_position = {}
			}

			// ADD LOGIC HERE FOR hiding hand while card is selected and being placed
			// when selected and grid world target position or whatever its called
			// then push down the rest of the hand smoothly like we do for the shop


			rotation_amount: f32 = math.lerp(f32(-1.0), f32(1.0), ratio)


			rotation := rotation_amount * 10


			max_y := f32(2.0 * f32(0.5) * (1.0 - f32(0.5))) * 80


			outline_color: rl.Color = rl.WHITE
			if game.selected_card_index == i {
				outline_color = rl.GREEN
			} else if hover {
				outline_color = rl.BLUE
			}


			if game.gold < card.cost {
				outline_color = {200, 0, 0, 255}
			}

			selected := game.selected_card_index == i
			selected_or_hover := selected || hover


			color := rl.WHITE


			target: f32 = selected_or_hover ? 1.2 : 1.0


			position.y -= selected_or_hover ? max_y - fan_y_amount : 0

			if selected_or_hover {
				target_pos.y -= 40
			} else {
				card.last_frame_state = .None
			}

			animate_v2_to_target(&card.position, target_pos, dt, 5.0)

			animate_v2_to_target(&card.scale, {target, target}, dt, 8.0)
			target_rot: f32 = selected_or_hover ? 0 : rotation_amount * 10
			animate_to_target_f32(&card.rotation, target_rot, dt)

			if selected {
				if aabb_center_contains(
					position,
					{CARD_WIDTH, CARD_HEIGHT} * card.scale,
					mouse_world_position,
				) {
					color.a = 50
					outline_color.a = 180
				}
				card.last_frame_state = .Selected
			}

			if selected_or_hover {

				draw_sprite(
					position,
					.Card_Highlight,
					{CARD_WIDTH, CARD_HEIGHT},
					outline_color,
					.center_center,
					{},
					card.scale,
					false,
					selected_or_hover ? 10 : 0,
					card.rotation,
				)
			}


			draw_sprite(
				position,
				get_card_render_texture(card.type),
				{CARD_WIDTH, CARD_HEIGHT},
				color,
				.center_center,
				{},
				card.scale,
				false,
				selected_or_hover ? 10 : 0,
				card.rotation,
			)

		}

	}


	// @SELECTED CARD
	{
		// draw_frame.camera_xform = translate_mat4(
		// 	Vector3{-camera.position.x, -camera.position.y, 0},
		// )
		// set_ortho_projection(game.camera_zoom)
		mouse_world_position := rl.GetScreenToWorld2D(
			get_mouse_position(),
			draw_frame.layer[.cards].camera,
		)


		if rl.IsKeyReleased(.ESCAPE) {
			game.selected_card_index = -1
		}

		if game.selected_card_index != -1 && mouse_inside_tile {
			set_z_layer(.game_play)
			card := game.hand[game.selected_card_index]
			image_id: Texture_Name = get_card_image_id(card.type)


			tile := &game.tiles[mouse_tile_grid_pos.y * GRID_SIZE_X + mouse_tile_grid_pos.x]

			if game.selected_card_grid_placement_position != mouse_tile_grid_pos {
				game.selected_card_grid_placement_position = mouse_tile_grid_pos
				game.can_place_selected_card = true
				for &path in game.enemy_paths {
					temp_path := find_path(game.player_base_grid_position, path.start_position)

					if temp_path == nil || len(temp_path) == 0 {
						log("CANT PLACE")
						game.can_place_selected_card = false
					} else {
						clear(&path.path)
						path.path = temp_path
					}
				}
			}


			for tree in game.trees {
				if world_to_grid_pos(tree.position) == mouse_tile_grid_pos {
					game.can_place_selected_card = false
					break
				}
			}


			if mouse_tile_grid_pos == game.player_base_grid_position {
				game.can_place_selected_card = false
			}


			if tile.card_type != .nil {
				game.can_place_selected_card = false
			}

			//@placing @attack_range
			card_range := get_card_range(card.type)
			card_attack_style := get_attack_range_style(card.type)
			if card_range > 0 {

				for pos in get_attack_positions(mouse_tile_grid_pos, card_range, card.type) {
					draw_sprite(
						grid_to_world_pos(mouse_tile_grid_pos + pos),
						.Selection_Cursor,
						{16, 16},
						rl.Color{255, 255, 255, 0.8 * 255},
					)
				}


			}


			draw_sprite(
				grid_to_world_pos(mouse_tile_grid_pos) -
				get_entity_tile_placement_pos(card.type) -
				{0, 2.0},
				image_id,
				get_card_entity_size(card.type),
				game.can_place_selected_card ? rl.WHITE : rl.Color{0.8 * 255, 0, 0, 0.8 * 255},
			)

			// @PLACING CARDS
			if IsMouseButtonPressed(.LEFT) &&
			   game.can_place_selected_card &&
			   game.gold >= card.cost {
				capture_mouse_pressed(.LEFT)
				card := game.hand[game.selected_card_index]
				defer game.selected_card_index = -1
				defer game.selected_card_grid_placement_position = {}
				tile := &game.tiles[mouse_tile_grid_pos.y * GRID_SIZE_X + mouse_tile_grid_pos.x]
				action_type := get_card_action_type(card.type)
				game.gold -= card.cost
				if tile.card_type == .nil && action_type == .Placement {
					tile.card_type = card.type
					ordered_remove(&game.hand, game.selected_card_index)
					ent: Entity
					ent.active = true
					ent.card_type = card.type
					ent.grid_position = mouse_tile_grid_pos
					ent.attack_amount = 1
					ent.range = get_card_range(card.type)
					ent.position = grid_to_world_pos(ent.grid_position)
					if ent.range > 0 {
						found, pos := find_closest_path_to_entity(mouse_tile_grid_pos)
						if found {
							if pos.x < ent.grid_position.x {
								ent.flipped = true
							}
						}
					}

					ent.movable = get_card_movable(card.type)
					ent.ent_type = get_card_ent_type(card.type)
					append(&game.entities, ent)
					create_money_popup(-card.cost, ent.position)

					if ent.card_type == .PoisionTile {
						emitter: ParticleEmitter

						emitter = create_emitter(
							ent.position,
							{0, -16},
							{8, 8},
							{1.0, 1.5},
							fire_rate = 0.1,
							lifetime = 1.0,
							amount = 1,
							randomness = 0.5,
						)

						emitter.color = rl.PURPLE
						emitter.forever = true

						append(&game.particle_emitters, emitter)
					}

					p: SpriteParticle = particle_create(
						.Placement_Particles,
						ent.position + {0, 5},
					)
					append(&game.sprite_particle, p)
				} else if tile.card_type != .nil && action_type == .Action {
					ordered_remove(&game.hand, game.selected_card_index)
				}
			}

		}
	}


	cleanup_base_entity(&game.popup_text)
	cleanup_base_entity(&game.player_projectiles)
	cleanup_base_entity(&game.sprite_particle)
}


// @round_start
// @setup_run
// @start_run
on_round_start :: proc() {
	game.gold += 10
	paths := rand.int31_max(2) + 2

	for &path in game.enemy_paths {
		clear(&path.path)
		clear(&path.enemies)
	}


	clear(&game.enemy_paths)
	// Pick points for enemy spawns

	for enemy_paths: i32 = 0; enemy_paths < paths; enemy_paths += 1 {
		direction := rand.int31_max(len(CardinalDirection))
		starting_pos := Vector2Int{}
		switch (CardinalDirection(direction)) {
		case .North:
			starting_pos = {auto_cast rand.int31_max(auto_cast GRID_SIZE_X - 1), GRID_SIZE_Y - 1}
		case .East:
			starting_pos = {GRID_SIZE_X - 1, auto_cast rand.int31_max(auto_cast GRID_SIZE_Y)}
		case .South:
			starting_pos = {auto_cast rand.int31_max(auto_cast GRID_SIZE_X), 0}

		case .West:
			starting_pos = {0, auto_cast rand.int31_max(auto_cast GRID_SIZE_Y)}
		}


		node_path: NodePath
		node_path.start_direction = CardinalDirection(direction)
		node_path.start_position = starting_pos
		node_path.path = find_path(game.player_base_grid_position, starting_pos)
		path_index := len(game.enemy_paths)


		enemies_per_path := rand.int31_max(10) + 5

		for enemy_i: i32 = 0; enemy_i < enemies_per_path; enemy_i += 1 {
			enemy: Enemy
			enemy.health = get_enemy_health(enemy.type)
			enemy.max_health = get_enemy_health(enemy.type)
			enemy.enemy_spawn_timer = get_enemy_spawn_timer(enemy.type)
			enemy.speed = get_enemy_speed(enemy.type)
			append(&node_path.enemies, enemy)
		}

		append(&game.enemy_paths, node_path)

		for &ent in game.entities {
			ent.position = grid_to_world_pos(ent.grid_position)
		}

		game.draw_card_cost = INITIAL_DRAW_CARD_COST
		generate_shop_items()
	}


	discard_hand()

	for i := 0; i < game.cards_per_hand; i += 1 {
		draw_card()
	}

	// provide resources
	for tile in game.tiles {
		generate_resource(tile.card_type)
	}
}


particle_create :: proc(anim: Animation_Name, position: Vector2) -> SpriteParticle {
	a := atlas_animations[anim]

	return {
		current_frame = a.first_frame,
		atlas_anim = anim,
		timer = atlas_textures[a.first_frame].duration,
		active = true,
		position = position,
	}
}
