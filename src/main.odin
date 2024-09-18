package main

import rl "vendor:raylib"

WIDTH :: 720
HEIGHT :: 1280

Player :: struct {
	body: rl.Rectangle,
}

Enemy :: struct {
	body:   rl.Rectangle,
	color:  rl.Color,
	health: i32,
	speed:  i32,
}

GameState :: struct {
	player:  Player,
	enemies: [dynamic]Enemy,
}

Game := GameState{}

draw_player :: proc(player: ^Player) {
	rl.DrawRectangleRec(player.body, rl.GREEN)
}

draw_enemy :: proc(enemy: ^Enemy) {
	rl.DrawRectangleRec(enemy.body, enemy.color)
}

tick_player :: proc() {
	if rl.IsKeyDown(.A) {
		Game.player.body.x = max(Game.player.body.x - 10, 8)
	}
	if rl.IsKeyDown(.D) {
		Game.player.body.x = min(Game.player.body.x + 10, WIDTH - (Game.player.body.width + 8))
	}

	draw_player(&Game.player)
}

tick_enemy :: proc(enemy: ^Enemy) {
	enemy.body.y += f32(enemy.speed)
}

tick_enemies :: proc() {
	for &enemy in Game.enemies {
		tick_enemy(&enemy)
		draw_enemy(&enemy)
	}
}

game_tick :: proc() {
	tick_player()
	tick_enemies()
}

main :: proc() {
	rl.SetTraceLogLevel(.ERROR)
	rl.SetConfigFlags({.MSAA_4X_HINT, .VSYNC_HINT})

	rl.InitWindow(WIDTH, HEIGHT, "SIC")
	defer rl.CloseWindow()

	rl.SetWindowPosition(WIDTH * 2, HEIGHT / 2)
	rl.SetTargetFPS(144)

	Game.player = Player {
		body = rl.Rectangle{WIDTH - 100, HEIGHT - 100, 50, 50},
	}
	Game.enemies = make([dynamic]Enemy)
	enemy := Enemy {
		body   = rl.Rectangle{WIDTH / 2, 0, 25, 25},
		color  = rl.RED,
		health = 100,
		speed  = 3,
	}
	append(&Game.enemies, enemy)

	for !rl.WindowShouldClose() {
		free_all(context.temp_allocator)

		rl.BeginDrawing()
		rl.ClearBackground(rl.GRAY)

		game_tick()

		rl.DrawFPS(2, 2)
		rl.EndDrawing()
	}
}
