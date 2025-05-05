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


import rl "vendor:raylib"


SCREEN_WIDTH :: 800
SCREEN_HEIGHT :: 450


main :: proc() {
	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Game")
	defer rl.CloseWindow()

	init_game()

	rl.SetTargetFPS(60)

	for !rl.WindowShouldClose() {
		update_game()
		draw_game()
	}
}


init_game :: proc() {

}


update_game :: proc() {

}

draw_game :: proc() {
	render_frame()
}
