package main

import "core:time"
import rl "vendor:raylib"

WIDTH :: 720
HEIGHT :: 1280

GameState :: enum {
	MainMenu,
	Running,
	Won,
	Lost,
	Exit,
}

Game :: struct {
	player:                   Player,
	enemies:                  [dynamic]Enemy,
	projectiles:              [dynamic]Projectile,
	state:                    GameState,
	game_time:                f32,
	spawn_accum_time:         f32,
	special_spawn_accum_time: f32,
}

TheGame := Game{}

state_running :: proc() {
	tick_player()
	tick_enemies()
	tick_projectiles()
}

state_main_menu :: proc() {
	rl.DrawText("Main Menu", 100, 100, 42, rl.BLACK)
	rl.DrawText("Press 1 to play", 125, 150, 32, rl.BLACK)
	rl.DrawText("Press 2 to exit", 125, 200, 32, rl.BLACK)

	if rl.IsKeyReleased(.ONE) {
		TheGame.state = .Running
	}
	if rl.IsKeyReleased(.TWO) {
		TheGame.state = .Exit
	}
}

state_won :: proc() {
	rl.DrawText("You Won!", WIDTH / 2 - 150, HEIGHT / 2 - 100, 72, rl.BLACK)
	rl.DrawText("Press 1 to play again", 125, 150, 32, rl.BLACK)
	rl.DrawText("Press 2 to exit", 125, 200, 32, rl.BLACK)

	if rl.IsKeyReleased(.ONE) {
		reset_game_state()
	}
	if rl.IsKeyReleased(.TWO) {
		TheGame.state = .Exit
	}
}

state_lost :: proc() {
	rl.DrawText("You Lost!", WIDTH / 2 - 150, HEIGHT / 2 - 100, 72, rl.BLACK)
	rl.DrawText("Press 1 to play again", 125, 150, 32, rl.BLACK)
	rl.DrawText("Press 2 to exit", 125, 200, 32, rl.BLACK)

	if rl.IsKeyReleased(.ONE) {
		reset_game_state()
	}
	if rl.IsKeyReleased(.TWO) {
		TheGame.state = .Exit
	}
}

reset_game_state :: proc() {
	delete(TheGame.enemies)
	delete(TheGame.projectiles)

	TheGame.player = create_player()
	TheGame.enemies = make([dynamic]Enemy)
	TheGame.projectiles = make([dynamic]Projectile)
	TheGame.state = .Running
	TheGame.game_time = 0
	TheGame.spawn_accum_time = 0
	TheGame.special_spawn_accum_time = 0
}

set_initial_game_state :: proc() {
	now := time.now()
	rl.SetRandomSeed(u32(time.to_unix_seconds(now)))

	TheGame.player = create_player()
	TheGame.enemies = make([dynamic]Enemy)
	TheGame.projectiles = make([dynamic]Projectile)
	TheGame.state = .MainMenu
	TheGame.game_time = 0
	TheGame.spawn_accum_time = 0
	TheGame.special_spawn_accum_time = 0
}

check_win_state :: proc() {
	if len(TheGame.enemies) == 0 &&
	   TheGame.player.health > 0 &&
	   TheGame.state == .Running &&
	   TheGame.game_time > (60 * 3) {
		TheGame.state = .Won
	}
}

main :: proc() {
	rl.SetTraceLogLevel(.ERROR)
	rl.SetConfigFlags({.MSAA_4X_HINT, .VSYNC_HINT})

	rl.InitWindow(WIDTH, HEIGHT, "SIC")
	defer rl.CloseWindow()

	rl.SetWindowPosition(WIDTH * 2, HEIGHT / 2)
	rl.SetTargetFPS(144)

	set_initial_game_state()

	for !rl.WindowShouldClose() {
		free_all(context.temp_allocator)

		TheGame.game_time += rl.GetFrameTime()

		rl.BeginDrawing()
		rl.ClearBackground(rl.GRAY)

		check_win_state()

		switch TheGame.state {
		case .MainMenu:
			state_main_menu()
		case .Running:
			state_running()
		case .Won:
			state_won()
		case .Lost:
			state_lost()
		case .Exit:
			return
		}

		rl.DrawFPS(2, 2)
		rl.EndDrawing()
	}
}
