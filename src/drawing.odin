package main

import "core:slice"
import rl "vendor:raylib"


DrawCallType :: enum {
	Sprite,
	Rect,
	Text,
}


ShaderType :: enum {
	None,
	flash_hit,
}

DrawCall :: struct {
	type:                      DrawCallType,
	position:                  Vector2,
	scale:                     Vector2,
	rotation:                  f32,
	texture_name:              Texture_Name,
	color:                     rl.Color,
	source:                    rl.Rectangle,
	size:                      Vector2,
	text:                      cstring,
	font_size:                 f32,
	pivot:                     Pivot,
	rect:                      Rect,
	outline:                   f32,
	outline_color:             rl.Color,
	flipped_x:                 bool,
	z_index:                   int,
	shader:                    ShaderType,
	shader_values:             map[i32]rawptr,
	shader_uniform_data_types: map[i32]rl.ShaderUniformDataType,
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


shaders: map[ShaderType]rl.Shader

init_gfx :: proc() {
	size := get_pixel_screen_size()
	screen_shader = rl.LoadShader("", "assets/shaders/scanlines.fs")
	outline_text_shader = rl.LoadShader("", "assets/shaders/outline.fs")
	shaders[.flash_hit] = rl.LoadShader("", "assets/shaders/flash_hit.fs")
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
		slice.sort_by(layer.draw_calls[:], proc(i, e: DrawCall) -> bool {
			return i.z_index < e.z_index
		})

		for draw_call in layer.draw_calls {
			origin := draw_call.size * scale_from_pivot(draw_call.pivot) * draw_call.scale

			src := draw_call.rect
			src.width = src.width * draw_call.scale.x
			src.height = src.height * draw_call.scale.y
			switch draw_call.type {
			case .Sprite:
				if draw_call.shader != .None {
					shader := shaders[draw_call.shader]


					for dataLoc in draw_call.shader_values {
						data := draw_call.shader_values[dataLoc]
						uniform_value := draw_call.shader_uniform_data_types[dataLoc]
						rl.SetShaderValue(shader, dataLoc, data, uniform_value)
					}
					rl.BeginShaderMode(shader)
				}
				rl.DrawTexturePro(
					atlas,
					{
						width = draw_call.flipped_x ? draw_call.rect.width * -1 : draw_call.rect.width,
						height = draw_call.rect.height,
						x = draw_call.rect.x,
						y = draw_call.rect.y,
					},
					{
						width = draw_call.size.x * draw_call.scale.x,
						height = draw_call.size.y * draw_call.scale.y,
						x = draw_call.position.x,
						y = draw_call.position.y,
					},
					origin,
					draw_call.rotation,
					draw_call.color,
				)

				if draw_call.shader != .None {
					rl.EndShaderMode()
					delete(draw_call.shader_values)
					delete(draw_call.shader_uniform_data_types)
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
				font_size := draw_call.font_size * draw_call.scale.x
				if draw_call.outline > 0 {
					rl.DrawTextPro(
						raylib_font,
						draw_call.text,
						draw_call.position + {-draw_call.outline, -draw_call.outline},
						origin,
						draw_call.rotation,
						font_size,
						1.0,
						draw_call.outline_color,
					)
					rl.DrawTextPro(
						raylib_font,
						draw_call.text,
						draw_call.position + {-draw_call.outline, draw_call.outline},
						origin,
						draw_call.rotation,
						font_size,
						1.0,
						draw_call.outline_color,
					)

					rl.DrawTextPro(
						raylib_font,
						draw_call.text,
						draw_call.position + {draw_call.outline, -draw_call.outline},
						origin,
						draw_call.rotation,
						font_size,
						1.0,
						draw_call.outline_color,
					)
					rl.DrawTextPro(
						raylib_font,
						draw_call.text,
						draw_call.position + {draw_call.outline, draw_call.outline},
						origin,
						draw_call.rotation,
						font_size,
						1.0,
						draw_call.outline_color,
					)


					rl.DrawTextPro(
						raylib_font,
						draw_call.text,
						draw_call.position + {draw_call.outline, 0},
						origin,
						draw_call.rotation,
						font_size,
						1.0,
						draw_call.outline_color,
					)
					rl.DrawTextPro(
						raylib_font,
						draw_call.text,
						draw_call.position + {0, draw_call.outline},
						origin,
						draw_call.rotation,
						font_size,
						1.0,
						draw_call.outline_color,
					)
					rl.DrawTextPro(
						raylib_font,
						draw_call.text,
						draw_call.position + {-draw_call.outline, 0},
						origin,
						draw_call.rotation,
						font_size,
						1.0,
						draw_call.outline_color,
					)
					rl.DrawTextPro(
						raylib_font,
						draw_call.text,
						draw_call.position + {0, -draw_call.outline},
						origin,
						draw_call.rotation,
						font_size,
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
					font_size,
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
	flipped_x := false,
	z_index := 0,
	rotation: f32 = 0,
) -> ^DrawCall {
	draw_call: DrawCall
	draw_call.position = position
	draw_call.type = .Sprite
	draw_call.pivot = pivot
	draw_call.scale = scale
	draw_call.color = color
	draw_call.flipped_x = flipped_x
	draw_call.rotation = rotation

	draw_call.z_index = z_index + len(draw_frame.layer[draw_frame.active_z_layer].draw_calls)
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

	return append_draw_call(draw_call)
}


set_shader_value :: proc(
	draw_call: ^DrawCall,
	uniform_name: cstring,
	value: rawptr,
	uniform_type: rl.ShaderUniformDataType,
) {
	shader := shaders[draw_call.shader]
	location := rl.GetShaderLocation(shader, uniform_name)
	draw_call.shader_values[location] = value
	draw_call.shader_uniform_data_types[location] = uniform_type
	assert(location > -1)
	// rl.SetShaderValue(shader, location, value, uniform_type)
}

draw_rect :: proc(
	position: Vector2,
	size: Vector2,
	color: rl.Color = rl.WHITE,
	pivot: Pivot = .center_center,
	z_index := 0,
) {
	draw_call: DrawCall
	draw_call.position = position
	draw_call.scale = 1.0
	draw_call.type = .Rect
	draw_call.size = size
	draw_call.color = color
	draw_call.pivot = pivot
	draw_call.z_index = z_index + len(draw_frame.layer[draw_frame.active_z_layer].draw_calls)

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
	scale := Vector2{1, 1},
	z_index := 0,
) -> ^DrawCall {
	draw_call: DrawCall
	draw_call.position = position
	draw_call.scale = scale
	draw_call.type = .Text
	draw_call.font_size = font_size
	draw_call.text = text
	draw_call.color = color
	draw_call.pivot = pivot
	draw_call.outline = outline
	draw_call.outline_color = outline_color
	draw_call.z_index = z_index + len(draw_frame.layer[draw_frame.active_z_layer].draw_calls)

	draw_call.size = rl.MeasureTextEx(
		raylib_font,
		draw_call.text,
		auto_cast draw_call.font_size,
		1.0,
	)

	return append_draw_call(draw_call)
}

append_draw_call :: proc(draw_call: DrawCall) -> ^DrawCall {
	append(&draw_frame.layer[draw_frame.active_z_layer].draw_calls, draw_call)
	return(
		&draw_frame.layer[draw_frame.active_z_layer].draw_calls[len(draw_frame.layer[draw_frame.active_z_layer].draw_calls) - 1] \
	)
}
