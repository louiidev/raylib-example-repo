package main

import rl "vendor:raylib"


ImageId :: enum {
    nil,
}

Image_Column_Rows_Count := [ImageId][2]int {
	.nil              = {0, 0},
}

raylib_texture: rl.Texture2D