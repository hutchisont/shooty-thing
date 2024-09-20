package main

import rl "vendor:raylib"

Projectile :: struct {
	body:   rl.Rectangle,
	color:  rl.Color,
	speed:  f32,
	damage: i32,
}

create_projectile :: proc() -> Projectile {
	return Projectile {
		body = rl.Rectangle {
			TheGame.player.body.x + (TheGame.player.body.width / 2) - 5,
			TheGame.player.body.y,
			10,
			20,
		},
		color = rl.PURPLE,
		speed = 400,
		damage = 15,
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

draw_projectile :: proc(projectile: ^Projectile) {
	rl.DrawRectangleRec(projectile.body, projectile.color)
}
