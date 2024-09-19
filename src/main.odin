package main

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
	player:      Player,
	enemies:     [dynamic]Enemy,
	projectiles: [dynamic]Projectile,
	state:       GameState,
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
	to_remove := make([dynamic]int)
	defer delete(to_remove)

	for &enemy, index in TheGame.enemies {
		if tick_enemy(&enemy) {
			draw_enemy(&enemy)
		} else {
			append(&to_remove, index)
		}
	}

	for value in to_remove {
		unordered_remove(&TheGame.enemies, value)
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
	to_remove := make([dynamic]int)
	defer delete(to_remove)

	for &projectile, index in TheGame.projectiles {
		if tick_projectile(&projectile) {
			draw_projectile(&projectile)
		} else {
			append(&to_remove, index)
		}
	}

	for value in to_remove {
		unordered_remove(&TheGame.projectiles, value)
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
	enemy := Enemy {
		body   = rl.Rectangle{WIDTH / 2, 0, 25, 25},
		color  = rl.RED,
		health = 100,
		speed  = 200,
		damage = 110,
	}
	append(&TheGame.enemies, enemy)
	TheGame.projectiles = make([dynamic]Projectile)
	TheGame.state = .Running
}

set_initial_game_state :: proc() {
	TheGame.player = create_player()
	TheGame.enemies = make([dynamic]Enemy)
	enemy := Enemy {
		body   = rl.Rectangle{WIDTH / 2, 0, 25, 25},
		color  = rl.RED,
		health = 100,
		speed  = 200,
		damage = 110,
	}
	append(&TheGame.enemies, enemy)
	TheGame.projectiles = make([dynamic]Projectile)
	TheGame.state = .MainMenu
}

check_win_state :: proc() {
	if len(TheGame.enemies) == 0 &&
	   TheGame.player.health > 0 &&
	   TheGame.state == .Running {
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
