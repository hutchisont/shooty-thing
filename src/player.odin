package main

import rl "vendor:raylib"

Player :: struct {
	body:                      rl.Rectangle,
	health:                    i32,
	speed:                     f32,
	accumulated_time:          f32,
	projectile_size_mult:      f32,
	projectile_dmg_mult:       f32,
	projectile_fire_threshold: f32,
	cur_exp:                   u32,
	exp_to_level:              u32,
	level:                     u32,
}

create_player :: proc() -> Player {
	return Player {
		body = {WIDTH - 100, HEIGHT - 100, 50, 50},
		health = 100,
		speed = 400,
		exp_to_level = 75,
		projectile_fire_threshold = 0.5,
		projectile_size_mult = 1,
		projectile_dmg_mult = 1,
		level = 1,
	}
}

level_up_player :: proc() {
	pl := &TheGame.player

	// 5% bigger
	pl.projectile_size_mult *= 1.05

	// 5% more damage
	pl.projectile_dmg_mult *= 1.05

	// 5% lower threshold
	pl.projectile_fire_threshold = pl.projectile_fire_threshold * .95
	pl.projectile_fire_threshold = rl.Clamp(pl.projectile_fire_threshold, .01, 5)

	pl.level += 1
}

gain_exp_player :: proc(exp: u32) {
	pl := &TheGame.player
	pl.cur_exp += exp
	for pl.cur_exp > pl.exp_to_level {
		pl.cur_exp -= pl.exp_to_level
		level_up_player()
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
	if pl.accumulated_time > pl.projectile_fire_threshold {
		append(&TheGame.projectiles, create_projectile())
		pl.accumulated_time = 0
	}

	draw_player(pl)
}

draw_player :: proc(player: ^Player) {
	rl.DrawRectangleRec(player.body, rl.GREEN)
}
