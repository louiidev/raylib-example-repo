package main

import rl "vendor:raylib"


Transform :: struct {
	position: Vector2,
	scale:    f32,
	rotation: f32,
}

DrawCallType :: enum {
	Sprite,
	Rect,
	Text,
}


DrawCall :: struct {
	type:      DrawCallType,
	transform: Transform,
	img_id:    ImageId,
	color:     rl.Color,
	source:    rl.Rectangle,
	size:      Vector2,
	text:      cstring,
	font_size: f32,
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


render_frame :: proc() {
	rl.BeginDrawing()
	defer rl.EndDrawing()
	rl.ClearBackground(rl.RAYWHITE)

	for layer, layer_name in draw_frame.layer {

		rl.BeginMode2D(layer.camera)
		defer rl.EndMode2D()
		for draw_call in layer.draw_calls {
			switch draw_call.type {
			case .Sprite:
				rl.DrawTexturePro(
					raylib_texture,
					draw_call.source,
					{
						x = draw_call.transform.position.x,
						y = draw_call.transform.position.y,
						width = draw_call.size.x,
						height = draw_call.size.y,
					},
					{},
					draw_call.transform.rotation,
					rl.WHITE,
				)
			case .Rect:
				rl.DrawRectanglePro(
					{
						x = draw_call.transform.position.x,
						y = draw_call.transform.position.y,
						width = draw_call.size.x,
						height = draw_call.size.y,
					},
					{},
					draw_call.transform.rotation,
					rl.WHITE,
				)
			case .Text:
				rl.DrawTextPro(
					raylib_font,
					draw_call.text,
					draw_call.transform.position,
					{},
					draw_call.transform.rotation,
					32,
					1.0,
					draw_call.color,
				)
			}
		}
	}
}


draw_sprite :: proc(position, size: Vector2, img_id: ImageId, color: rl.Color = rl.WHITE) {
	draw_call: DrawCall
	draw_call.transform = {
		position = position,
		scale    = 1.0,
	}
	draw_call.img_id = img_id
	draw_call.size = size
	draw_call.color = color

	append_draw_call(draw_call)
}

append_draw_call :: proc(draw_call: DrawCall) {
	append(&draw_frame.layer[draw_frame.active_z_layer].draw_calls, draw_call)
}
