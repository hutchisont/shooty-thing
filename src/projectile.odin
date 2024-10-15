package main

import rl "vendor:raylib"

base_size : [2]f32: {10, 20}
base_dmg :: 15

Projectile :: struct {
	size_mult: f32,
	body:   rl.Rectangle,
	color:  rl.Color,
	speed:  f32,
	damage: f32,
}

projectile_create :: proc() -> Projectile {
	width := base_size.x * TheGame.player.projectile_size_mult
	centered_x := (TheGame.player.body.x + (TheGame.player.body.width / 2)) - (width / 2)
	return Projectile {
		body = rl.Rectangle {
			centered_x,
			TheGame.player.body.y,
			width,
			base_size.y * TheGame.player.projectile_size_mult,
		},
		color = rl.PURPLE,
		speed = 400 * TheGame.player.projectile_speed_mult,
		damage = base_dmg * TheGame.player.projectile_dmg_mult,
	}
}

projectile_tick :: proc(projectile: ^Projectile) -> (alive: bool) {
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

projectile_tick_all :: proc() {
	#reverse for &projectile, index in TheGame.projectiles {
		if projectile_tick(&projectile) {
			projectile_draw(&projectile)
		} else {
			unordered_remove(&TheGame.projectiles, index)
		}
	}
}

projectile_draw :: proc(projectile: ^Projectile) {
	rl.DrawRectangleRec(projectile.body, projectile.color)
}
