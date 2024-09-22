package main

import "core:fmt"
import "core:math/rand"
import "core:strconv"
import "core:strings"
import "core:time"
import rl "vendor:raylib"

WIDTH :: 720
HEIGHT :: 1280

GameState :: enum {
	MainMenu,
	Running,
	LevelUp,
	Won,
	Lost,
	Exit,
}

LevelOptions :: enum {
	ProjectileSize,
	FireRate,
	Damage,
	MoveSpeed,
	BulletSpeed,
}


Game :: struct {
	player:                   Player,
	enemies:                  [dynamic]Enemy,
	projectiles:              [dynamic]Projectile,
	state:                    GameState,
	game_time:                f32,
	spawn_accum_time:         f32,
	special_spawn_accum_time: f32,
	level_up_options:         [dynamic]LevelOptions,
	level_options_text:       [LevelOptions]cstring,
}

TheGame := Game{}

state_running :: proc() {
	tick_player()
	tick_enemies()
	tick_projectiles()
}

generate_random_level_options :: proc() {
	option_count :: 3

	gen: for option_count > len(TheGame.level_up_options) {
		option := rand.choice_enum(LevelOptions)
		for o in TheGame.level_up_options {
			if option == o {
				continue gen
			}
		}
		append(&TheGame.level_up_options, option)
	}
}


state_level_up :: proc() {
	if 0 == len(TheGame.level_up_options) {
		generate_random_level_options()
	}

	options_text: [3]cstring
	options_text[0] = fmt.ctprintf(
		"Press 1 %s",
		TheGame.level_options_text[TheGame.level_up_options[0]],
	)
	options_text[1] = fmt.ctprintf(
		"Press 2 %s",
		TheGame.level_options_text[TheGame.level_up_options[1]],
	)
	options_text[2] = fmt.ctprintf(
		"Press 3 %s",
		TheGame.level_options_text[TheGame.level_up_options[2]],
	)

	rl.DrawText(options_text[0], 125, 150, 32, rl.BLACK)
	rl.DrawText(options_text[1], 125, 200, 32, rl.BLACK)
	rl.DrawText(options_text[2], 125, 250, 32, rl.BLACK)

	handled_input := false
	picked_index := -1
	if rl.IsKeyReleased(.ONE) {
		handled_input = true
		picked_index = 0
	} else if rl.IsKeyReleased(.TWO) {
		handled_input = true
		picked_index = 1
	} else if rl.IsKeyReleased(.THREE) {
		handled_input = true
		picked_index = 2
	}


	if handled_input {
		apply_level_up_upgrade(TheGame.level_up_options[picked_index])
		clear(&TheGame.level_up_options)
		if 0 == TheGame.player.pending_levels {
			TheGame.state = .Running
		}
	}
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
	clear(&TheGame.enemies)
	clear(&TheGame.projectiles)
	clear(&TheGame.level_up_options)

	TheGame.player = create_player()
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
	TheGame.level_up_options = make([dynamic]LevelOptions)
	TheGame.level_options_text = {
		.ProjectileSize = "to upgrade projectile size",
		.FireRate       = "to upgrade fire rate",
		.Damage         = "to upgrade damage",
		.MoveSpeed      = "to upgrade move speed",
		.BulletSpeed    = "to upgrade bullet speed",
	}
}

check_win_state :: proc() {
	if TheGame.player.health > 0 && TheGame.state == .Running && TheGame.game_time > (60 * 5) {
		TheGame.state = .Won
	}
}

draw_player_status :: proc() {
	clevel := fmt.ctprintf("Lvl: %d", TheGame.player.level)
	chp := fmt.ctprintf("Hp: %d", TheGame.player.health)
	rl.DrawText(clevel, 10, HEIGHT - 100, 32, rl.BLACK)
	rl.DrawText(chp, 10, HEIGHT - 50, 32, rl.BLACK)
}

draw_all_entities :: proc() {
	for &e in TheGame.enemies {
		draw_enemy(&e)
	}
	for &p in TheGame.projectiles {
		draw_projectile(&p)
	}
	draw_player(&TheGame.player)
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
		case .LevelUp:
			draw_all_entities()
			state_level_up()
		case .Won:
			state_won()
		case .Lost:
			state_lost()
		case .Exit:
			return
		}

		if TheGame.state != .MainMenu {
			draw_player_status()
		}

		rl.DrawFPS(2, 2)
		rl.EndDrawing()
	}
}
