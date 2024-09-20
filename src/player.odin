package main

import rl "vendor:raylib"

Player :: struct {
	body:                      rl.Rectangle,
	health:                    i32,
	speed:                     f32,
	accumulated_time:          f32,
	projectile_size_mult:      f32,
	projectile_fire_threshold: f32,
	projectile_fire_mult:      f32,
}

create_player :: proc() -> Player {
	return Player {
		body = {WIDTH - 100, HEIGHT - 100, 50, 50},
		health = 100,
		speed = 400,
		accumulated_time = 0,
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

	pl.accumulated_time += frame_time
	if pl.accumulated_time >
	   (pl.projectile_fire_threshold - (pl.projectile_fire_threshold * pl.projectile_fire_mult)) {
		append(&TheGame.projectiles, create_projectile())
		pl.accumulated_time = 0
	}

	draw_player(pl)
}

draw_player :: proc(player: ^Player) {
	rl.DrawRectangleRec(player.body, rl.GREEN)
}
