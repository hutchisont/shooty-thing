package main

import rl "vendor:raylib"

WIDTH :: 720
HEIGHT :: 1280

Player :: struct {
	body:   rl.Rectangle,
	health: i32,
	speed: f32,
}

Enemy :: struct {
	body:   rl.Rectangle,
	color:  rl.Color,
	health: i32,
	speed:  f32,
	damage: i32,
}

GameState :: enum {
	MainMenu,
	Running,
	Won,
	Lost,
}

Game :: struct {
	player:  Player,
	enemies: [dynamic]Enemy,
	state:   GameState,
}

TheGame := Game{}

draw_player :: proc(player: ^Player) {
	rl.DrawRectangleRec(player.body, rl.GREEN)
}

draw_enemy :: proc(enemy: ^Enemy) {
	rl.DrawRectangleRec(enemy.body, enemy.color)
}

tick_player :: proc() {
	pl := TheGame.player
	if rl.IsKeyDown(.A) {
		pl.body.x = max(pl.body.x - pl.speed, 8)
	}
	if rl.IsKeyDown(.D) {
		pl.body.x = min(pl.body.x + pl.speed, WIDTH - (pl.body.width + 8))
	}

	if pl.health <= 0 {
		TheGame.state = .Lost
	}

	draw_player(&pl)
}

tick_enemy :: proc(enemy: ^Enemy) {
	if enemy.body.y >= HEIGHT {
		TheGame.player.health -= enemy.damage
	} else {
		enemy.body.y += enemy.speed
	}
}

tick_enemies :: proc() {
	for &enemy in TheGame.enemies {
		tick_enemy(&enemy)
		draw_enemy(&enemy)
	}
}

state_running :: proc() {
	tick_player()
	tick_enemies()
}

state_main_menu :: proc() {
	rl.DrawText("Main Menu", 100, 100, 32, rl.BLACK)
}

state_won :: proc() {
	rl.DrawText("You Won!", WIDTH / 2 - 150, HEIGHT / 2 - 100, 72, rl.BLACK)
}

state_lost :: proc() {
	rl.DrawText("You Lost!", WIDTH / 2 - 150, HEIGHT / 2 - 100, 72, rl.BLACK)
}

game_tick :: proc() {
	switch TheGame.state {
	case .MainMenu:
		state_main_menu()
	case .Running:
		state_running()
	case .Won:
		state_won()
	case .Lost:
		state_lost()
	}
}

main :: proc() {
	rl.SetTraceLogLevel(.ERROR)
	rl.SetConfigFlags({.MSAA_4X_HINT, .VSYNC_HINT})

	rl.InitWindow(WIDTH, HEIGHT, "SIC")
	defer rl.CloseWindow()

	rl.SetWindowPosition(WIDTH * 2, HEIGHT / 2)
	rl.SetTargetFPS(144)

	TheGame.player = Player {
		body   = rl.Rectangle{WIDTH - 100, HEIGHT - 100, 50, 50},
		health = 100,
		speed = 10,
	}
	TheGame.enemies = make([dynamic]Enemy)
	enemy := Enemy {
		body   = rl.Rectangle{WIDTH / 2, 0, 25, 25},
		color  = rl.RED,
		health = 100,
		speed  = 3,
		damage = 110,
	}
	append(&TheGame.enemies, enemy)
	TheGame.state = .MainMenu

	for !rl.WindowShouldClose() {
		free_all(context.temp_allocator)

		rl.BeginDrawing()
		rl.ClearBackground(rl.GRAY)

		game_tick()

		rl.DrawFPS(2, 2)
		rl.EndDrawing()
	}
}
