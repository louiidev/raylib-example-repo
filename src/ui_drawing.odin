package main

import "core:fmt"
import "core:math"
import "core:math/ease"
import "core:math/linalg"
import rl "vendor:raylib"


// draw_rect_bordered_center_xform :: proc(
// 	position: Vector2,
// 	size: Vector2,
// 	border_size: f32,
// 	col := rl.WHITE,
// 	border_color := rl.WHITE,
// ) {
// 	border_size_v := size + border_size
// 	center_xform :=
// 		xform *
// 		linalg.matrix4_translate(Vector3{-border_size_v.x * 0.5, -border_size_v.y * 0.5, 0.0})
// 	draw_quad_xform_in_frame(
// 		{
// 			size = size + border_size,
// 			uv = {DEFAULT_UV.xy, DEFAULT_UV.xw, DEFAULT_UV.zw, DEFAULT_UV.zy},
// 			color = border_color,
// 			img_id = .nil,
// 		},
// 		center_xform,
// 		&draw_frame,
// 	)

// 	center_xform = xform * linalg.matrix4_translate(Vector3{-size.x * 0.5, -size.y * 0.5, 0.0})
// 	draw_quad_xform_in_frame(
// 		{
// 			size = size,
// 			uv = {DEFAULT_UV.xy, DEFAULT_UV.xw, DEFAULT_UV.zw, DEFAULT_UV.zy},
// 			color = col,
// 			img_id = .nil,
// 		},
// 		center_xform,
// 		&draw_frame,
// 	)
// }

// draw_rect_bordered_xform :: proc(
// 	position: Vector2,
// 	size: Vector2,
// 	border_size: f32,
// 	col := rl.WHITE,
// 	border_color := rl.WHITE,
// ) {
// 	border_size_v := size + border_size
// 	border_xform :=
// 		xform * linalg.matrix4_translate(Vector3{-border_size * 0.5, -border_size * 0.5, 0.0})
// 	draw_quad_xform_in_frame(
// 		{
// 			size = size + border_size,
// 			uv = {DEFAULT_UV.xy, DEFAULT_UV.xw, DEFAULT_UV.zw, DEFAULT_UV.zy},
// 			color = border_color,
// 			img_id = .nil,
// 		},
// 		border_xform,
// 		&draw_frame,
// 	)

// 	draw_quad_xform_in_frame(
// 		{
// 			size = size,
// 			uv = {DEFAULT_UV.xy, DEFAULT_UV.xw, DEFAULT_UV.zw, DEFAULT_UV.zy},
// 			color = col,
// 			img_id = .nil,
// 		},
// 		xform,
// 		&draw_frame,
// 	)
// }

// UiID :: u32

// BUTTON_BORDER_SIZE :: 8
// BUTTON_COLOR: Vector4 : {0.5, 0.5, 0.5, 1}
// BUTTON_HOVER_COLOR: Vector4 : {0.3, 0.3, 0.3, 1}
// BUTTON_BORDER_COLOR: Vector4 : {1, 1, 1, 1}
// BUTTON_DISABLED_COLOR: Vector4 : {0.1, 0.1, 0.1, 1.0}
// BUTTON_SELECTED_COLOR: Vector4 : {0.1, 0.6, 1.0, 1}
// bordered_button :: proc(
// 	position: Vector2,
// 	size: Vector2,
// 	text: string,
// 	font_size: f32,
// 	id: UiID,
// 	disabled: bool = false,
// 	selected: bool = false,
// ) -> bool {
// 	xform := transform_2d(position)
// 	color := BUTTON_COLOR
// 	if !disabled && aabb_center_contains(position, size, mouse_world_position) {
// 		ui_state.hover_id = id
// 		color = BUTTON_HOVER_COLOR
// 	}
// 	if !disabled && inputs.mouse_just_pressed[sapp.Mousebutton.LEFT] && ui_state.hover_id == id {
// 		ui_state.down_clicked_id = id
// 		consume_mouse_just_pressed(.LEFT)
// 	}


// 	if disabled {
// 		color = BUTTON_DISABLED_COLOR
// 	}

// 	if selected {
// 		color = BUTTON_SELECTED_COLOR
// 	}

// 	pressed := false

// 	if !disabled &&
// 	   ui_state.hover_id == id &&
// 	   inputs.mouse_just_released[sapp.Mousebutton.LEFT] &&
// 	   ui_state.down_clicked_id == id {
// 		pressed = true
// 		consume_mouse_just_released(.LEFT)
// 	}


// 	draw_rect_bordered_center_xform(xform, size, BUTTON_BORDER_SIZE, color, BUTTON_BORDER_COLOR)


// 	draw_text_center_center(transform_2d(position), text, font_size)


// 	return pressed
// }

// TEXT_BUTTON_COLOR: Vector4 : {0.7, 0.7, 0.7, 1}
// TEXT_HOVER_COLOR :: rl.WHITE

// text_button :: proc(
// 	position: Vector2,
// 	text: string,
// 	font_size: f32,
// 	id: UiID,
// 	disabled: bool = false,
// ) -> bool {
// 	xform := transform_2d(position)

// 	size := measure_text(text, font_size) * 1.5
// 	center_pos := position + size * 0.5 - {20, 10}
// 	color := BUTTON_COLOR
// 	if !disabled && aabb_contains(center_pos, size, mouse_world_position) {
// 		ui_state.hover_id = id
// 		color = BUTTON_HOVER_COLOR
// 	}
// 	if !disabled && inputs.mouse_down[sapp.Mousebutton.LEFT] && ui_state.hover_id == id {
// 		ui_state.down_clicked_id = id
// 	}


// 	if ui_state.hover_id == id {
// 		t := ui_state.hover_time / HOVER_TIME
// 		eased_t: f32 = ease.elastic_out(ui_state.hover_id == id ? t : 0)
// 		start_value: f32 = 0.0
// 		end_value: f32 = 20.0
// 		current_value := start_value + eased_t * (end_value - start_value)
// 		draw_quad_xform(
// 			transform_2d(position + {current_value + size.x * 0.75, -2.5}),
// 			{32, 32},
// 			.arrow,
// 			DEFAULT_UV,
// 		)
// 	}

// 	// if disabled {
// 	// 	color = BUTTON_DISABLED_COLOR
// 	// }

// 	pressed := false

// 	if !disabled &&
// 	   ui_state.hover_id == id &&
// 	   inputs.mouse_just_released[sapp.Mousebutton.LEFT] &&
// 	   ui_state.down_clicked_id == id {
// 		pressed = true
// 		consume_mouse_just_released(.LEFT)
// 	}

// 	{
// 		t := ui_state.hover_time / HOVER_TIME
// 		eased_t: f32 = ease.elastic_out(ui_state.hover_id == id ? t * 1 : 0)
// 		start_value: f32 = 0.0
// 		end_value: f32 = 20.0
// 		current_value := start_value + eased_t * (end_value - start_value)
// 		draw_text_outlined(
// 			transform_2d(position + {current_value, 0}),
// 			text,
// 			font_size,
// 			3,
// 			4.0,
// 			ui_state.hover_id == id ? TEXT_HOVER_COLOR : TEXT_BUTTON_COLOR,
// 			COLOR_BLACK,
// 		)
// 	}


// 	return pressed
// }

UiID :: u32


last_pressed_id: UiID
image_button :: proc(
	position: Vector2,
	text: cstring,
	font_size: f32,
	id: UiID,
	size: Vector2 = {60 * 4, 24 * 4},
	disabled: bool = false,
	color_override := rl.WHITE,
	border_override := rl.BLACK,
) -> bool {
	log(size)

	x_frame := 0
	hover_position: Vector2 = {0, 0}
	color := rl.WHITE
	hover := false
	if !disabled && aabb_center_contains(position, size, get_mouse_position()) {
		hover = true
		x_frame = 1
		hover_position.y += 5
	}
	if !disabled && IsMouseButtonDown(.LEFT) && hover {
		hover_position.y -= 5
		last_pressed_id = id
	}


	if disabled {
		x_frame = 3
	}

	pressed := false

	if !disabled && hover && IsMouseButtonPressed(.LEFT) && last_pressed_id == id {
		pressed = true
		last_pressed_id = 0
	}


	uv := get_sprite_rect(.Buttons, {x_frame, 0}, Vector2{60, 24})
	shadow_uv := get_sprite_rect(.Buttons, {4, 0}, Vector2{60, 24})


	draw_sprite(position + {-5, -5}, .Buttons, size, color_override, .center_center, shadow_uv)
	draw_sprite(position + hover_position, .Buttons, size, color_override, .center_center, uv)

	draw_text(
		position + hover_position,
		text,
		font_size,
		color_override,
		.center_center,
		4.0,
		border_override,
	)

	return pressed
}


// 	draw_text_outlined_center(
// 		transform_2d(position - {0, 8} + hover_position),
// 		text,
// 		font_size,
// 		0.0,
// 		4.0,
// 		color_override,
// 		border_override,
// 	)


// 	return pressed
// }


draw_button :: proc(
	position, size: Vector2,
	text: cstring,
	font_size: f32,
	disabled := false,
	selected := false,
	border_size: f32 = .0,
) -> bool {
	color := rl.WHITE
	mouse_position := rl.GetMousePosition()
	hover := false
	if !disabled && aabb_center_contains(position, size, mouse_position) {
		// ui_state.hover_id = id
		hover = true
		color = rl.GREEN
	}
	if !disabled && IsMouseButtonPressed(.LEFT) && hover {
		capture_mouse_pressed(.LEFT)
	}


	if disabled {
		color = rl.GRAY
	}

	if selected {
		color = rl.BLUE
	}

	pressed := false

	if !disabled && hover && IsMouseButtonReleased(.LEFT) {
		pressed = true
		capture_mouse_released(.LEFT)
	}
	if border_size > 0 {
		draw_rect(position, size + border_size * 2, rl.GRAY)
	}
	draw_rect(position, size, color)
	draw_text(position, text, 32, rl.BLACK)


	return pressed
}


splash_screen_logic :: proc(dt: f32, next_state: AppState, fade_time: f64) -> rl.Color {
	if rl.IsKeyPressed(.SPACE) {
		game.app_state = next_state
	}

	switch game.ux_anim_state {
	case .fade_in:
		reached := animate_to_target_f32(&game.ux_alpha, 1.0, dt, rate = 3.0, good_enough = 0.05)
		if reached {
			game.ux_anim_state = .hold
			game.hold_end_time = app_now() + fade_time
		}
	case .hold:
		if app_now() >= game.hold_end_time {
			game.ux_anim_state = .fade_out
		}


	case .fade_out:
		reached := animate_to_target_f32(&game.ux_alpha, 0.0, dt, rate = 5.0, good_enough = 0.05)
		if reached {
			game.ux_state = {}
			game.app_state = next_state
		}
	}

	alpha: f32 = 255 * game.ux_alpha
	color: rl.Color = {255, 255, 255, auto_cast alpha}

	return color
}
