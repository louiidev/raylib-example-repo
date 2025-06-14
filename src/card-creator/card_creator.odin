package card_creator

import game "../../src/"
import "core:fmt"
import rl "vendor:raylib"


CARD_SCALE: f32 = 4.0
raylib_font: rl.Font
atlas: rl.Texture
main :: proc() {
	flags: rl.ConfigFlags = {.WINDOW_RESIZABLE}
	rl.SetConfigFlags(flags)
	rl.InitWindow(512, 512, "Game")


	atlas = rl.LoadTexture("assets/atlas.png")
	raylib_font = rl.LoadFont("assets/fonts/m6x11.ttf")

	for card in game.CardType {
		if card == .nil {
			continue
		}

		card_size := game.atlas_textures[.Card].document_size * CARD_SCALE

		renderTexture := rl.LoadRenderTexture(auto_cast card_size.x, auto_cast card_size.y)
		invertedTexture := rl.LoadRenderTexture(auto_cast card_size.x, auto_cast card_size.y)

		// Draw to the texture
		rl.BeginTextureMode(renderTexture)
		rl.ClearBackground({0, 0, 0, 0})


		draw_sprite(.Card, card_size * 0.5)

		name := game.get_card_name(card)


		card_image_id := game.get_card_image_id(card)

		draw_sprite(
			card_image_id,
			game.Vector2{card_size.x * 0.5, card_size.y * 0.5 - 15 * CARD_SCALE},
			{},
			game.get_card_entity_size(card) * CARD_SCALE,
		)

		resource_placement_y: f32 = 12
		icon_pos_x: f32 = -26

		outline_size: f32 = 3.0
		font_size: f32 = 40

		text_placement := game.Vector2{card_size.x * 0.5, 40}


		draw_text(game.get_card_name(card), text_placement, font_size, outline_size)


		draw_sprite(
			.Ui,
			game.Vector2{card_size.x * 0.5, card_size.y * 0.5 - 15 * CARD_SCALE} +
			{-8, 35} * CARD_SCALE,
			game.get_sprite_rect(.Ui, {}, 16),
			{14, 14} * CARD_SCALE,
		)

		draw_text(
			game.to_c_string(fmt.tprintf("$%d", game.get_card_resource_cost(card))),
			text_placement + {0, 50} * CARD_SCALE,
			48,
			outline_size,
		)


		rl.EndTextureMode()

		rl.BeginTextureMode(invertedTexture)
		rl.ClearBackground({0, 0, 0, 0})
		rl.DrawTextureRec(
			renderTexture.texture,
			{0, 0, card_size.x, card_size.y},
			{0, 0},
			rl.WHITE,
		)


		rl.EndTextureMode()


		image := rl.LoadImageFromTexture(invertedTexture.texture)

		output := rl.ExportImage(
			image,
			game.to_c_string(fmt.tprintf("assets/textures/%s", game.get_card_file_name(card))),
		)
		rl.UnloadImage(image)
	}


	// Save the render texture to a PNG file


}


draw_text :: proc(text: cstring, text_placement: game.Vector2, font_size: f32, outline_size: f32) {
	rl.DrawTextPro(
		raylib_font,
		text,
		text_placement - {0, -outline_size},
		rl.MeasureTextEx(raylib_font, text, font_size, 1.0) *
		game.scale_from_pivot(.center_center),
		0,
		font_size,
		1.0,
		rl.BLACK,
	)

	rl.DrawTextPro(
		raylib_font,
		text,
		text_placement - {0, outline_size},
		rl.MeasureTextEx(raylib_font, text, font_size, 1.0) *
		game.scale_from_pivot(.center_center),
		0,
		font_size,
		1.0,
		rl.BLACK,
	)

	rl.DrawTextPro(
		raylib_font,
		text,
		text_placement - {-outline_size, 0},
		rl.MeasureTextEx(raylib_font, text, font_size, 1.0) *
		game.scale_from_pivot(.center_center),
		0,
		font_size,
		1.0,
		rl.BLACK,
	)

	rl.DrawTextPro(
		raylib_font,
		text,
		text_placement - {outline_size, 0},
		rl.MeasureTextEx(raylib_font, text, font_size, 1.0) *
		game.scale_from_pivot(.center_center),
		0,
		font_size,
		1.0,
		rl.BLACK,
	)

	rl.DrawTextPro(
		raylib_font,
		text,
		text_placement - {outline_size, outline_size},
		rl.MeasureTextEx(raylib_font, text, font_size, 1.0) *
		game.scale_from_pivot(.center_center),
		0,
		font_size,
		1.0,
		rl.BLACK,
	)

	rl.DrawTextPro(
		raylib_font,
		text,
		text_placement - {-outline_size, outline_size},
		rl.MeasureTextEx(raylib_font, text, font_size, 1.0) *
		game.scale_from_pivot(.center_center),
		0,
		font_size,
		1.0,
		rl.BLACK,
	)

	rl.DrawTextPro(
		raylib_font,
		text,
		text_placement - {outline_size, -outline_size},
		rl.MeasureTextEx(raylib_font, text, font_size, 1.0) *
		game.scale_from_pivot(.center_center),
		0,
		font_size,
		1.0,
		rl.BLACK,
	)

	rl.DrawTextPro(
		raylib_font,
		text,
		text_placement,
		rl.MeasureTextEx(raylib_font, text, font_size, 1.0) *
		game.scale_from_pivot(.center_center),
		0,
		font_size,
		1.0,
		rl.WHITE,
	)
}


draw_sprite :: proc(
	texture: game.Texture_Name,
	position: game.Vector2,
	rect: rl.Rectangle = {},
	size: game.Vector2 = {},
) {
	rect := rect
	if rect == {} {
		rect = game.atlas_textures[texture].rect
	}

	size := size
	if size == {} {
		size = game.atlas_textures[texture].document_size * CARD_SCALE
	}


	origin := size * game.scale_from_pivot(.center_center)
	rl.DrawTexturePro(
		atlas,
		rect,
		{width = size.x, height = size.y, x = position.x, y = position.y},
		origin,
		0,
		rl.WHITE,
	)
}
