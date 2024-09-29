package main

import "core:c"
import "core:fmt"
import "core:math/rand"
import "core:strconv"
import "core:strings"
import "core:time"
import rl "vendor:raylib"

WIDTH :: 720
HEIGHT :: 1280
GAME_DURATION_FAST :: 60 * 5
GAME_DURATION_MEDIUM :: 60 * 10
GAME_DURATION_LONG :: 60 * 20
MENU_BG_COLOR: rl.Color : {255, 255, 255, 135}

Difficulty :: enum {
	Easy,
	Medium,
	Hard,
	Infinite,
}

Durations := [Difficulty]f32 {
	.Easy     = GAME_DURATION_FAST,
	.Medium   = GAME_DURATION_MEDIUM,
	.Hard     = GAME_DURATION_LONG,
	.Infinite = -1,
}

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
	difficulty:               Difficulty,
	game_time:                f32,
	spawn_accum_time:         f32,
	special_spawn_accum_time: f32,
	level_up_options:         [dynamic]LevelOptions,
	level_options_text:       [LevelOptions]cstring,
}

TheGame := Game{}

state_running :: proc() {
	TheGame.game_time += rl.GetFrameTime()
	tick_player()
	tick_enemies()
	tick_projectiles()
	draw_countdown_text()
	draw_player_status()
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
	draw_all_entities()

	FONT_SIZE :: 32
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

	text_width := max(
		rl.MeasureText(options_text[0], FONT_SIZE),
		rl.MeasureText(options_text[1], FONT_SIZE),
		rl.MeasureText(options_text[2], FONT_SIZE),
	)

	rl.DrawRectangle((WIDTH - text_width - 20) / 2, 135, text_width + 40, 165, MENU_BG_COLOR)

	rl.DrawText(options_text[0], (WIDTH - text_width) / 2, 150, FONT_SIZE, rl.BLACK)
	rl.DrawText(options_text[1], (WIDTH - text_width) / 2, 200, FONT_SIZE, rl.BLACK)
	rl.DrawText(options_text[2], (WIDTH - text_width) / 2, 250, FONT_SIZE, rl.BLACK)

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
	draw_countdown_text()
	draw_player_status()
}

state_main_menu :: proc() {
	rl.DrawText("Main Menu", 100, 100, 42, rl.BLACK)
	rl.DrawText("Press 1 for easy ", 125, 150, 32, rl.BLACK)
	rl.DrawText("Press 2 for medium", 125, 200, 32, rl.BLACK)
	rl.DrawText("Press 3 for hard", 125, 250, 32, rl.BLACK)
	rl.DrawText("Press 4 for infinite", 125, 300, 32, rl.BLACK)
	rl.DrawText("Press 5 to exit", 125, 350, 32, rl.BLACK)

	if rl.IsKeyReleased(.ONE) {
		TheGame.difficulty = .Easy
		TheGame.state = .Running
	}
	if rl.IsKeyReleased(.TWO) {
		TheGame.difficulty = .Medium
		TheGame.state = .Running
	}
	if rl.IsKeyReleased(.THREE) {
		TheGame.difficulty = .Hard
		TheGame.state = .Running
	}
	if rl.IsKeyReleased(.FOUR) {
		TheGame.difficulty = .Infinite
		TheGame.state = .Running
	}
	if rl.IsKeyReleased(.FIVE) {
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
	draw_player_status()
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
	draw_player_status()
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
		.BulletSpeed    = "to upgrade projectile speed",
	}
}

check_win_state :: proc() {
	if .Infinite != TheGame.difficulty &&
	   0 <= TheGame.player.cur_health &&
	   .Running == TheGame.state &&
	   TheGame.game_time >= Durations[TheGame.difficulty] {
		TheGame.state = .Won
	}
}

draw_player_status :: proc() {
	FONT_SIZE :: 32
	clevel := fmt.ctprintf("Lvl: %d", TheGame.player.level)
	max_size := rl.MeasureText(clevel, FONT_SIZE)
	rl.DrawText(clevel, 3, 3, FONT_SIZE, rl.BLACK)

	hp := rl.Rectangle{3, 32, WIDTH / 3, 10}
	lvl := rl.Rectangle{3, 48, WIDTH / 3, 10}
	rl.DrawRectangleLines(
		c.int(hp.x) - 1,
		c.int(hp.y) - 1,
		c.int(hp.width) + 2,
		c.int(hp.height) + 2,
		rl.BLACK,
	)
	rl.DrawRectangleLines(
		c.int(lvl.x) - 1,
		c.int(lvl.y) - 1,
		c.int(lvl.width) + 2,
		c.int(lvl.height) + 2,
		rl.BLACK,
	)
	hp_percent: f32 = f32(TheGame.player.cur_health) / f32(TheGame.player.max_health)
	rl.DrawRectangleRec({hp.x, hp.y, (hp.width * hp_percent), hp.height}, rl.RED)
	lvl_percent: f32 = f32(TheGame.player.cur_exp) / f32(TheGame.player.exp_to_level)
	rl.DrawRectangleRec({lvl.x, lvl.y, (lvl.width * lvl_percent), lvl.height}, rl.PURPLE)
}

draw_all_entities :: proc() {
	draw_player(&TheGame.player)
	for &e in TheGame.enemies {
		draw_enemy(&e)
	}
	for &p in TheGame.projectiles {
		draw_projectile(&p)
	}
}

secs_to_mins_and_secs :: proc(seconds: i32) -> (mins: i32, secs: i32) {
	secs = seconds % 60
	mins = i32(seconds / 60)
	return mins, secs
}

draw_countdown_text :: proc() {
	FONT_SIZE :: 48
	time_to_check: f32 = 0
	if .Infinite == TheGame.difficulty {
		time_to_check = TheGame.game_time
	} else {
		time_to_check = Durations[TheGame.difficulty] - TheGame.game_time
		if 0 == time_to_check {
			return
		}
	}
	mins, secs := secs_to_mins_and_secs(i32(time_to_check))
	if 0 == mins {
		text := fmt.ctprintf("%d", secs)
		text_width := rl.MeasureText(text, FONT_SIZE)
		x := (WIDTH - text_width) / 2
		rl.DrawRectangleRec({f32(x - 10), 20, f32(text_width + 20), FONT_SIZE + 2}, MENU_BG_COLOR)
		rl.DrawText(text, x, 25, FONT_SIZE, rl.BLACK)
	} else {
		text := fmt.ctprintf("%d:%2d", mins, secs)
		text_width := rl.MeasureText(text, FONT_SIZE)
		x := (WIDTH - text_width) / 2
		rl.DrawRectangleRec({f32(x - 10), 20, f32(text_width + 20), FONT_SIZE + 2}, MENU_BG_COLOR)
		rl.DrawText(text, x, 25, FONT_SIZE, rl.BLACK)
	}
}

draw_fps :: proc() {
	FPS_FONT_SIZE :: 26
	fps := rl.GetFPS()
	clvl := fmt.ctprintf("%d", fps)
	clvl_width := rl.MeasureText(clvl, FPS_FONT_SIZE)
	rl.DrawText(clvl, WIDTH - clvl_width - 5, 2, FPS_FONT_SIZE, rl.DARKGREEN)
}

main :: proc() {
	rl.SetTraceLogLevel(.ERROR)
	rl.SetConfigFlags({.MSAA_4X_HINT, .VSYNC_HINT})

	rl.InitWindow(WIDTH, HEIGHT, "Shooty Thing")
	defer rl.CloseWindow()

	rl.SetWindowPosition(WIDTH * 2, HEIGHT / 2)
	rl.SetTargetFPS(144)

	set_initial_game_state()

	for !rl.WindowShouldClose() {
		free_all(context.temp_allocator)

		rl.BeginDrawing()
		rl.ClearBackground(rl.GRAY)

		check_win_state()

		switch TheGame.state {
		case .MainMenu:
			state_main_menu()
		case .Running:
			state_running()
		case .LevelUp:
			state_level_up()
		case .Won:
			state_won()
		case .Lost:
			state_lost()
		case .Exit:
			return
		}

		draw_fps()
		rl.EndDrawing()
	}
}
