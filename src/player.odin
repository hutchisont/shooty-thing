package main

import rl "vendor:raylib"

Player :: struct {
	body:                      rl.Rectangle,
	max_health:                i32,
	cur_health:                i32,
	display_health:            f32,
	speed:                     f32,
	accumulated_time:          f32,
	projectile_size_mult:      f32,
	projectile_speed_mult:     f32,
	projectile_dmg_mult:       f32,
	projectile_fire_threshold: f32,
	cur_exp:                   u32,
	display_exp:               f32,
	exp_to_level:              u32,
	level:                     u32,
	pending_levels:            u32,
}

create_player :: proc() -> Player {
	return Player {
		body = {WIDTH - 100, HEIGHT - 100, 50, 50},
		max_health = 100,
		cur_health = 100,
		speed = 200,
		exp_to_level = 75,
		projectile_fire_threshold = 0.5,
		projectile_size_mult = 1,
		projectile_speed_mult = 1,
		projectile_dmg_mult = 1,
		level = 1,
	}
}

level_up_player :: proc() {
	pl := &TheGame.player

	pl.pending_levels += 1

	TheGame.state = .LevelUp
}

apply_level_up_upgrade :: proc(upg: LevelOptions) {
	pl := &TheGame.player

	switch upg {
	case .ProjectileSize:
		// 10% bigger
		pl.projectile_size_mult *= 1.10
	case .FireRate:
		// 10% lower threshold
		pl.projectile_fire_threshold = rl.Clamp(pl.projectile_fire_threshold * .90, .01, 5)
	case .Damage:
		// 10% more damage
		pl.projectile_dmg_mult *= 1.10
	case .MoveSpeed:
		// 10% faster
		pl.speed *= 1.10
	case .BulletSpeed:
		// 10% faster
		pl.projectile_speed_mult *= 1.10
	}

	pl.pending_levels -= 1
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

	if pl.cur_health <= 0 {
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
	center := player.body.x + (player.body.width / 2)
	rl.DrawLineEx({center, player.body.y}, {center, HEIGHT / 5}, 3, {0, 0, 0, 55})
	rl.DrawRectangleRec(player.body, rl.GREEN)
}
