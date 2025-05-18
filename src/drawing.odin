package main

import rl "vendor:raylib"


DrawCallType :: enum {
	Sprite,
	Rect,
	Text,
}


DrawCall :: struct {
	type:          DrawCallType,
	position:      Vector2,
	scale:         Vector2,
	rotation:      f32,
	texture_name:  Texture_Name,
	color:         rl.Color,
	source:        rl.Rectangle,
	size:          Vector2,
	text:          cstring,
	font_size:     f32,
	pivot:         Pivot,
	rect:          Rect,
	outline:       f32,
	outline_color: rl.Color,
}


DrawLayer :: struct {
	draw_calls: [dynamic]DrawCall,
	camera:     rl.Camera2D,
}


DrawFrame :: struct {
	layer:          [ZLayer]DrawLayer,
	active_z_layer: ZLayer,
}

draw_frame: DrawFrame

raylib_font: rl.Font

ZLayer :: enum u8 {
	background,
	shadow,
	game_play,
	cards,
	particles,
	ui,
	// :layer
}


ZLayerQuadCount := [ZLayer]int {
	.background = 512,
	.shadow     = 128,
	.game_play  = 512,
	.cards      = 128,
	.particles  = 2048,
	.ui         = 256,
}


card_render_target: rl.RenderTexture2D
game_render_target: rl.RenderTexture2D
screen_render_target: rl.RenderTexture2D
screen_shader: rl.Shader
outline_text_shader: rl.Shader


init_gfx :: proc() {
	size := get_pixel_screen_size()
	screen_shader = rl.LoadShader("", "assets/shaders/scanlines.fs")
	outline_text_shader = rl.LoadShader("", "assets/shaders/outline.fs")
	game_render_target = rl.LoadRenderTexture(auto_cast size.x, auto_cast size.y)
	screen_render_target = rl.LoadRenderTexture(SCREEN_WIDTH, SCREEN_HEIGHT)
	card_render_target = rl.LoadRenderTexture(SCREEN_WIDTH, SCREEN_HEIGHT)

	rl.SetTextureFilter(game_render_target.texture, .POINT)


	// num_glyphs := len(atlas_glyphs)
	// font_rects := make([]Rect, num_glyphs)
	// glyphs := make([]rl.GlyphInfo, num_glyphs)

	// for ag, idx in atlas_glyphs {
	// 	font_rects[idx] = ag.rect
	// 	glyphs[idx] = {
	// 		value = ag.value,
	// 		offsetX = i32(ag.offset_x),
	// 		offsetY = i32(ag.offset_y),
	// 		advanceX = i32(ag.advance_x),
	// 	}
	// }

	raylib_font = rl.LoadFont("assets/fonts/m6x11.ttf")

	rl.SetShapesTexture(atlas, SHAPES_TEXTURE_RECT)
}

on_resize_gfx :: proc() {


	// GAMEPLAY RENDER TEXTURE
	size := get_pixel_screen_size()
	rl.UnloadRenderTexture(game_render_target)
	game_render_target = rl.LoadRenderTexture(auto_cast size.x, auto_cast size.y)
	rl.SetTextureFilter(game_render_target.texture, .POINT)

	// CARD RENDER TEXTURE
	// scale := SCREEN_HEIGHT / f32(rl.GetScreenHeight())
	// rl.UnloadRenderTexture(card_render_target)
	// card_render_target = rl.LoadRenderTexture(auto_cast f32(f32(SCREEN_WIDTH) * scale), SCREEN_HEIGHT)
	// rl.SetTextureFilter(card_render_target.texture, .POINT)


	// SCREEN RENDER TEXTURE
	rl.UnloadRenderTexture(screen_render_target)
	screen_render_target = rl.LoadRenderTexture(rl.GetScreenWidth(), rl.GetScreenHeight())
	log("WINDOW RESIZED", rl.GetScreenWidth(), rl.GetScreenHeight())
}


start_draw_frame :: proc() {
	for layer in ZLayer {
		count := ZLayerQuadCount[layer]
		draw_frame.layer[layer].draw_calls = make(
			[dynamic]DrawCall,
			0,
			count,
			allocator = context.temp_allocator,
		)
	}
}


clear_draw_frame :: proc() {
	for layer in ZLayer {
		clear(&draw_frame.layer[layer].draw_calls)
	}
}

set_z_layer :: proc(zlayer: ZLayer) {
	draw_frame.active_z_layer = zlayer
}


render_frame :: proc() {
	rl.BeginDrawing()
	defer rl.EndDrawing()
	color := hex_to_rgb(0x0d0d16)


	rl.ClearBackground(color)
	rl.BeginTextureMode(game_render_target)
	rl.ClearBackground(color)
	for layer, layer_name in draw_frame.layer {
		camera := layer.camera
		if camera == {} {
			camera = game.camera
		}
		rl.BeginMode2D(camera)
		defer rl.EndMode2D()

		if layer_name == .ui {
			rl.EndTextureMode()
			rl.BeginTextureMode(screen_render_target)


			rl.DrawTexturePro(
				game_render_target.texture,
				{
					0,
					0,
					auto_cast game_render_target.texture.width,
					auto_cast -game_render_target.texture.height,
				},
				{0, 0, auto_cast rl.GetScreenWidth(), auto_cast rl.GetScreenHeight()},
				{},
				0.0,
				rl.WHITE,
			)

		}
		for draw_call in layer.draw_calls {

			origin := draw_call.size * scale_from_pivot(draw_call.pivot)


			src := draw_call.rect
			src.width = src.width * draw_call.scale.x
			src.height = src.height * draw_call.scale.y
			switch draw_call.type {
			case .Sprite:
				if draw_call.outline > 0 {
					outline_color := normalize_color(draw_call.outline_color)
					outline := draw_call.outline
					rl.SetShaderValue(
						outline_text_shader,
						rl.GetShaderLocation(outline_text_shader, "outlineColor"),
						&outline_color,
						.VEC4,
					)
					rl.SetShaderValue(
						outline_text_shader,
						rl.GetShaderLocation(outline_text_shader, "outlineSize"),
						&outline,
						.FLOAT,
					)
					rl.BeginShaderMode(outline_text_shader)

				}
				rl.DrawTexturePro(
					atlas,
					src,
					{
						width = draw_call.size.x,
						height = draw_call.size.y,
						x = draw_call.position.x,
						y = draw_call.position.y,
					},
					origin,
					draw_call.rotation,
					draw_call.color,
				)

				if draw_call.outline > 0 {
					rl.EndShaderMode()

				}
			case .Rect:
				rl.DrawRectanglePro(
					{
						x = draw_call.position.x,
						y = draw_call.position.y,
						width = draw_call.size.x,
						height = draw_call.size.y,
					},
					origin,
					draw_call.rotation,
					draw_call.color,
				)
			case .Text:
				if draw_call.outline > 0 {
					rl.DrawTextPro(
						raylib_font,
						draw_call.text,
						draw_call.position + {-draw_call.outline, -draw_call.outline},
						origin,
						draw_call.rotation,
						draw_call.font_size,
						1.0,
						draw_call.outline_color,
					)
					rl.DrawTextPro(
						raylib_font,
						draw_call.text,
						draw_call.position + {-draw_call.outline, draw_call.outline},
						origin,
						draw_call.rotation,
						draw_call.font_size,
						1.0,
						draw_call.outline_color,
					)

					rl.DrawTextPro(
						raylib_font,
						draw_call.text,
						draw_call.position + {draw_call.outline, -draw_call.outline},
						origin,
						draw_call.rotation,
						draw_call.font_size,
						1.0,
						draw_call.outline_color,
					)
					rl.DrawTextPro(
						raylib_font,
						draw_call.text,
						draw_call.position + {draw_call.outline, draw_call.outline},
						origin,
						draw_call.rotation,
						draw_call.font_size,
						1.0,
						draw_call.outline_color,
					)


					rl.DrawTextPro(
						raylib_font,
						draw_call.text,
						draw_call.position + {draw_call.outline, 0},
						origin,
						draw_call.rotation,
						draw_call.font_size,
						1.0,
						draw_call.outline_color,
					)
					rl.DrawTextPro(
						raylib_font,
						draw_call.text,
						draw_call.position + {0, draw_call.outline},
						origin,
						draw_call.rotation,
						draw_call.font_size,
						1.0,
						draw_call.outline_color,
					)
					rl.DrawTextPro(
						raylib_font,
						draw_call.text,
						draw_call.position + {-draw_call.outline, 0},
						origin,
						draw_call.rotation,
						draw_call.font_size,
						1.0,
						draw_call.outline_color,
					)
					rl.DrawTextPro(
						raylib_font,
						draw_call.text,
						draw_call.position + {0, -draw_call.outline},
						origin,
						draw_call.rotation,
						draw_call.font_size,
						1.0,
						draw_call.outline_color,
					)
				}


				rl.DrawTextPro(
					raylib_font,
					draw_call.text,
					draw_call.position,
					origin,
					draw_call.rotation,
					draw_call.font_size,
					1.0,
					draw_call.color,
				)

			}
		}
	}

	rl.EndTextureMode()
	rl.BeginShaderMode(screen_shader)
	rl.DrawTexturePro(
		screen_render_target.texture,
		{
			0,
			0,
			auto_cast screen_render_target.texture.width,
			auto_cast -screen_render_target.texture.height,
		},
		{0, 0, auto_cast rl.GetScreenWidth(), auto_cast rl.GetScreenHeight()},
		{},
		0.0,
		rl.WHITE,
	)


	draw_call := DrawCall{}
	draw_call.outline = 50.0
	draw_call.outline_color = {0.0, 1.0, 1.0, 1.0}
	draw_call.size = {150, 150}

	rl.EndShaderMode()
	clear_draw_frame()

}


draw_sprite :: proc(
	position: Vector2,
	texture_name: Texture_Name,
	size: Vector2 = {},
	color: rl.Color = rl.WHITE,
	pivot: Pivot = .center_center,
	rect := Rect{},
	scale: Vector2 = {1.0, 1.0},
	outline: f32 = 0.0,
	outline_color := rl.BLACK,
) {
	draw_call: DrawCall
	draw_call.position = position
	draw_call.scale = 1.0
	draw_call.type = .Sprite
	draw_call.pivot = pivot
	draw_call.scale = scale
	draw_call.color = color
	draw_call.outline = outline
	draw_call.outline_color = outline_color

	draw_call.texture_name = texture_name
	if size == {} {
		draw_call.size = atlas_textures[texture_name].document_size
	} else {
		draw_call.size = size
	}

	if rect == {} {
		draw_call.rect = atlas_textures[draw_call.texture_name].rect
	} else {
		draw_call.rect = rect
	}

	draw_call.color = color

	append_draw_call(draw_call)
}


draw_rect :: proc(
	position: Vector2,
	size: Vector2,
	color: rl.Color = rl.WHITE,
	pivot: Pivot = .center_center,
) {
	draw_call: DrawCall
	draw_call.position = position
	draw_call.scale = 1.0
	draw_call.type = .Rect
	draw_call.size = size
	draw_call.color = color
	draw_call.pivot = pivot


	append_draw_call(draw_call)
}


draw_text :: proc(
	position: Vector2,
	text: cstring,
	font_size: f32 = 32,
	color: rl.Color = rl.WHITE,
	pivot: Pivot = .center_center,
	outline: f32 = 0.0,
	outline_color := rl.BLACK,
) {
	draw_call: DrawCall
	draw_call.position = position
	draw_call.scale = 1.0
	draw_call.type = .Text
	draw_call.font_size = font_size
	draw_call.text = text
	draw_call.color = color
	draw_call.pivot = pivot
	draw_call.outline = outline
	draw_call.outline_color = outline_color


	draw_call.size = rl.MeasureTextEx(
		raylib_font,
		draw_call.text,
		auto_cast draw_call.font_size,
		1.0,
	)

	append_draw_call(draw_call)
}

append_draw_call :: proc(draw_call: DrawCall) {
	append(&draw_frame.layer[draw_frame.active_z_layer].draw_calls, draw_call)
}
