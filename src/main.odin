package main

import "core:time"
import rl "vendor:raylib"

WIDTH :: 720
HEIGHT :: 1280

Player :: struct {
	body:             rl.Rectangle,
	health:           i32,
	speed:            f32,
	accumulated_time: f32,
}

create_player :: proc() -> Player {
	return Player {
		body = {WIDTH - 100, HEIGHT - 100, 50, 50},
		health = 100,
		speed = 400,
		accumulated_time = 0,
	}
}

Enemy :: struct {
	body:   rl.Rectangle,
	color:  rl.Color,
	health: i32,
	speed:  f32,
	damage: i32,
}

create_basic_enemy :: proc() -> Enemy {
	spawn_x := rl.GetRandomValue(0, WIDTH - 30)
	return Enemy {
		body = rl.Rectangle{f32(spawn_x), 0, 25, 25},
		color = rl.RED,
		health = 100,
		speed = 200,
		damage = 2,
	}
}

Projectile :: struct {
	body:   rl.Rectangle,
	color:  rl.Color,
	speed:  f32,
	damage: i32,
}

GameState :: enum {
	MainMenu,
	Running,
	Won,
	Lost,
	Exit,
}

Game :: struct {
	player:           Player,
	enemies:          [dynamic]Enemy,
	projectiles:      [dynamic]Projectile,
	state:            GameState,
	game_time:        f32,
	spawn_accum_time: f32,
}

TheGame := Game{}

draw_player :: proc(player: ^Player) {
	rl.DrawRectangleRec(player.body, rl.GREEN)
}

draw_enemy :: proc(enemy: ^Enemy) {
	rl.DrawRectangleRec(enemy.body, enemy.color)
}

draw_projectile :: proc(projectile: ^Projectile) {
	rl.DrawRectangleRec(projectile.body, projectile.color)
}

create_projectile :: proc() -> Projectile {
	return Projectile {
		body = rl.Rectangle{TheGame.player.body.x, TheGame.player.body.y, 10, 20},
		color = rl.PURPLE,
		speed = 400,
		damage = 15,
	}
}

tick_player :: proc() {
	pl := &TheGame.player

	frame_time := rl.GetFrameTime()
	if rl.IsKeyDown(.A) {
		pl.body.x = max(pl.body.x - (pl.speed * frame_time), 8)
	}
	if rl.IsKeyDown(.D) {
		pl.body.x = min(pl.body.x + (pl.speed * frame_time), WIDTH - (pl.body.width + 8))
	}

	if pl.health <= 0 {
		TheGame.state = .Lost
	}

	fire_threshold :: 0.3

	pl.accumulated_time += frame_time
	if pl.accumulated_time > fire_threshold {
		append(&TheGame.projectiles, create_projectile())
		pl.accumulated_time = 0
	}

	draw_player(pl)
}

tick_enemy :: proc(enemy: ^Enemy) -> (alive: bool) {
	if enemy.body.y >= HEIGHT {
		TheGame.player.health -= enemy.damage
		return false
	} else if enemy.health <= 0 {
		return false
	} else {
		enemy.body.y += enemy.speed * rl.GetFrameTime()
		return true
	}
}

tick_enemies :: proc() {
	#reverse for &enemy, index in TheGame.enemies {
		if tick_enemy(&enemy) {
			draw_enemy(&enemy)
		} else {
			unordered_remove(&TheGame.enemies, index)
		}
	}

	spawn_time :: .75

	TheGame.spawn_accum_time += rl.GetFrameTime()

	if TheGame.spawn_accum_time >= .75 {
		TheGame.spawn_accum_time = 0
		append(&TheGame.enemies, create_basic_enemy())
	}
}

tick_projectile :: proc(projectile: ^Projectile) -> (alive: bool) {
	if projectile.body.y < 0 {
		return false
	} else {
		projectile.body.y -= projectile.speed * rl.GetFrameTime()
	}

	for &enemy in TheGame.enemies {
		if rl.CheckCollisionRecs(enemy.body, projectile.body) {
			enemy.health -= projectile.damage
			return false
		}
	}

	return true
}

tick_projectiles :: proc() {
	#reverse for &projectile, index in TheGame.projectiles {
		if tick_projectile(&projectile) {
			draw_projectile(&projectile)
		} else {
			unordered_remove(&TheGame.projectiles, index)
		}
	}
}

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
	TheGame.spawn_accum_time = 0
	TheGame.game_time = 0
}

set_initial_game_state :: proc() {
	now := time.now()
	rl.SetRandomSeed(u32(time.to_unix_seconds(now)))

	TheGame.player = create_player()
	TheGame.enemies = make([dynamic]Enemy)
	TheGame.projectiles = make([dynamic]Projectile)
	TheGame.state = .MainMenu
	TheGame.spawn_accum_time = 0
	TheGame.game_time = 0
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
