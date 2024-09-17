package main

import rl "vendor:raylib"

WIDTH :: 720
HEIGHT :: 1280

Player :: struct {
	body: rl.Rectangle,
}

Enemy :: struct {
	body:   rl.Rectangle,
	health: i32,
}

draw_player :: proc(player: ^Player) {
	rl.DrawRectangleRec(player.body, rl.GREEN)
}

draw_enemy :: proc(enemy: ^Enemy) {
	rl.DrawRectangleRec(enemy.body, rl.RED)
}

main :: proc() {
	rl.SetTraceLogLevel(.ERROR)
	rl.SetConfigFlags({.MSAA_4X_HINT, .VSYNC_HINT})

	rl.InitWindow(WIDTH, HEIGHT, "SIC")
	defer rl.CloseWindow()
	curMon := rl.GetCurrentMonitor()
	rl.SetWindowPosition(WIDTH * 2, HEIGHT / 2)

	player := Player{rl.Rectangle{WIDTH - 100, HEIGHT - 100, 50, 50}}
	enemy := Enemy{rl.Rectangle{0, 0, 25, 25}, 100}

	for !rl.WindowShouldClose() {
		free_all(context.temp_allocator)

		if rl.IsKeyDown(.A) {
			player.body.x = max(player.body.x - 10, 8)
		}
		if rl.IsKeyDown(.D) {
			player.body.x = min(player.body.x + 10, WIDTH - (player.body.width + 8))
		}

		enemy.body.y += 3


		rl.BeginDrawing()

		rl.ClearBackground(rl.GRAY)

		draw_player(&player)
		draw_enemy(&enemy)


		rl.DrawFPS(2, 2)

		rl.EndDrawing()
	}
}
