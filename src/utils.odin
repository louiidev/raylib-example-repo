package main

import "base:intrinsics"
import "core:math"
import rl "vendor:raylib"

Pivot :: enum {
	center_center,
	bottom_left,
	bottom_center,
	bottom_right,
	center_left,
	center_right,
	top_left,
	top_center,
	top_right,
}
scale_from_pivot :: proc(pivot: Pivot) -> Vector2 {
	switch pivot {
	case .bottom_left:
		return Vector2{0.0, 0.0}
	case .bottom_center:
		return Vector2{0.5, 0.0}
	case .bottom_right:
		return Vector2{1.0, 0.0}
	case .center_left:
		return Vector2{0.0, 0.5}
	case .center_center:
		return Vector2{0.5, 0.5}
	case .center_right:
		return Vector2{1.0, 0.5}
	case .top_center:
		return Vector2{0.5, 1.0}
	case .top_left:
		return Vector2{0.0, 1.0}
	case .top_right:
		return Vector2{1.0, 1.0}
	}
	return {}
}


get_direction :: proc(a, b: Vector2Int) -> Vector2Int {
	return Vector2Int{b.x - a.x, b.y - a.y}
}

vector_to_dir :: proc(
	prev, curr: Vector2Int,
	default := CardinalDirection.West,
) -> CardinalDirection {
	v := curr - prev
	if v == {1, 0} {return .East}
	if v == {-1, 0} {return .West}
	if v == {0, -1} {return .North}
	if v == {0, 1} {return .South}


	// log("incorrect formated data", curr, prev)
	return default // default fallback
}


almost_equals :: proc(a, b, epsilon: f32) -> bool {
	return math.abs(a - b) <= epsilon
}

almost_equals_v2 :: proc(a, b: Vector2, epsilon: f32) -> bool {
	return almost_equals(a.x, b.x, epsilon) && almost_equals(a.y, b.y, epsilon)
}


cardinal_direction_to_vector :: proc(direction: CardinalDirection) -> Vector2Int {
	switch (direction) {
	case .North:
		return {0, 1}
	case .East:
		return {1, 0}
	case .South:
		return {0, -1}
	case .West:
		return {-1, 0}
	}

	assert(false)
	return {}
}


animate_to_target_f32 :: proc(
	value: ^f32,
	target: f32,
	delta_t: f32,
	rate: f32 = 15.0,
	good_enough: f32 = 0.001,
) -> bool {
	value^ += (target - value^) * (1.0 - math.pow_f32(2.0, -rate * delta_t))
	if almost_equals(value^, target, good_enough) {
		value^ = target
		return true // reached
	}
	return false
}


animate_v2_to_target :: proc(value: ^Vector2, target: Vector2, delta_t: f32, rate: f32) {
	animate_to_target_f32(&value.x, target.x, delta_t, rate)
	animate_to_target_f32(&value.y, target.y, delta_t, rate)
}


hex_to_rgb :: proc(hex: int) -> rl.Color {
	r := (hex >> 16) & 0xFF
	g := (hex >> 8) & 0xFF
	b := hex & 0xFF
	return rl.Color{auto_cast r, auto_cast g, auto_cast b, 255}
}


get_viewport_scale :: proc() -> f32 {
	scale := PIXEL_WINDOW_HEIGHT / f32(rl.GetScreenHeight())

	return scale
}

get_card_viewport_scale :: proc() -> f32 {
	scale := SCREEN_HEIGHT / f32(rl.GetScreenHeight())

	return scale
}

get_pixel_screen_size :: proc() -> Vector2 {
	scale := get_viewport_scale()

	return {f32(rl.GetScreenWidth()) * scale, PIXEL_WINDOW_HEIGHT}
}

get_card_screen_size :: proc() -> Vector2 {
	scale := get_card_viewport_scale()

	return {f32(rl.GetScreenWidth()) * scale, SCREEN_HEIGHT}
}

get_card_mouse_position :: proc() -> Vector2 {
	pos := rl.GetMousePosition()
	pixel_size := get_card_screen_size()
	scaleX := f32(pixel_size.x) / f32(rl.GetScreenWidth())
	scaleY := f32(pixel_size.y) / f32(rl.GetScreenHeight())
	return {pos.x * scaleX, pos.y * scaleY}
}


get_mouse_position :: proc() -> Vector2 {
	pos := rl.GetMousePosition()
	pixel_size := get_pixel_screen_size()
	scaleX := f32(pixel_size.x) / f32(rl.GetScreenWidth())
	scaleY := f32(pixel_size.y) / f32(rl.GetScreenHeight())
	return {pos.x * scaleX, pos.y * scaleY}
}


get_sprite_rect :: proc(
	texture_name: Texture_Name,
	sprite_index: Vector2Int,
	size: Vector2,
) -> Rect {
	rect := atlas_textures[texture_name].rect

	rect.width = size.x
	rect.height = size.y
	rect.x += f32(sprite_index.x) * size.x
	rect.y += f32(sprite_index.y) * size.y

	rect.x -= 1
	rect.y -= 1

	return rect
}

import "core:strings"
to_c_string :: proc(str: string, allocator := context.temp_allocator) -> cstring {
	c_string := strings.clone_to_cstring(str, allocator)

	return c_string
}

import "core:fmt"
format_cstring :: proc(str: string, args: ..any) -> cstring {
	return to_c_string(fmt.tprintf(str, args))
}

normalize_color :: proc(rl_color: rl.Color) -> Vector4 {
	return {
		f32(rl_color.r) / 255,
		f32(rl_color.g) / 255,
		f32(rl_color.b) / 255,
		f32(rl_color.a) / 255,
	}
}


find_closest_path_to_entity :: proc(ent_position: Vector2Int) -> (bool, Vector2Int) {
	closest: Vector2Int = {}
	found_path := false
	dist: f32 = 1000000000000
	for paths in game.enemy_paths {
		for path in paths.path {
			if manhattan_dist(path, ent_position) <= dist {

				if dist == manhattan_dist(path, ent_position) {
					if path.y == ent_position.y {
						closest = path
						found_path = true
						dist = manhattan_dist(path, ent_position)
					}
				} else {
					closest = path
					found_path = true
					dist = manhattan_dist(path, ent_position)
				}

			}
		}
	}

	return found_path, closest
}


cleanup_base_entity :: proc(data: ^[dynamic]$T) where intrinsics.type_is_struct(T) {
	// Iterate in reverse order to avoid issues when removing items
	for i := len(data) - 1; i >= 0; i -= 1 {
		if !data[i].active {
			ordered_remove(data, i)
		}
	}
}


sine_breathe_alpha :: proc(p: $T) -> T where intrinsics.type_is_float(T) {
	return (math.sin((p - .25) * 2.0 * math.PI) / 2.0) + 0.5
}

cos_breathe_alpha :: proc(p: $T) -> T where intrinsics.type_is_float(T) {
	return (math.cos((p - .25) * 2.0 * math.PI) / 2.0) + 0.5
}


run_every_seconds :: proc(s: f32) -> bool {

	test := f32(game.ticks) / f32(ticks_per_second)

	interval: f32 = s * f32(ticks_per_second)

	if interval < 1.0 {
		// 	log.error("run_every_seconds is ticking each frame, can't go faster than this")
	}

	run := (game.ticks % u64(interval)) == 0
	return run
}


import "core:math/rand"
random_ranged_vector2 :: proc(min: Vector2, max: Vector2) -> Vector2 {
	x := rand.float32_range(min.x, max.x)
	y := rand.float32_range(min.y, max.y)


	return {x, y}
}


create_popup :: proc(text_value: cstring, position: Vector2, color := rl.WHITE) {
	popup: PopupText
	popup.active = true
	popup.value = text_value
	popup.position = position
	popup.alpha = 255
	popup.color = color


	append(&game.popup_text, popup)
}


create_money_popup :: proc(value: int, position: Vector2) {
	cstring_value: cstring = to_c_string(
		fmt.tprintf((value > 0 ? "+$%d" : "-$%d"), math.abs(value)),
		context.allocator,
	)

	create_popup(cstring_value, position, {255, 215, 105, 255})
}

create_dmg_popup :: proc(value: int, position: Vector2) {
	cstring_value: cstring = to_c_string(fmt.tprintf("-%d", value), context.allocator)

	create_popup(cstring_value, position, rl.WHITE)
}

create_player_dmg_popup :: proc(value: int, position: Vector2) {
	cstring_value: cstring = to_c_string(fmt.tprintf("-%d", value), context.allocator)

	create_popup(cstring_value, position, rl.RED)
}
