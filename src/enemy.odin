package main

import rl "vendor:raylib"

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
		health = 25,
		speed = 200,
		damage = 2,
	}
}

create_beefy_enemy :: proc() -> Enemy {
	spawn_x := rl.GetRandomValue(0, WIDTH - 105)
	return Enemy {
		body = rl.Rectangle{f32(spawn_x), 0, 100, 75},
		color = rl.YELLOW,
		health = 250,
		speed = 70,
		damage = 50,
	}
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

	spawn_time :: 1.25
	special_spawn_time :: spawn_time * 7

	frame_time := rl.GetFrameTime()

	TheGame.spawn_accum_time += frame_time
	TheGame.special_spawn_accum_time += frame_time

	if TheGame.spawn_accum_time >= spawn_time {
		TheGame.spawn_accum_time = 0
		append(&TheGame.enemies, create_basic_enemy())
	}
	if TheGame.special_spawn_accum_time >= special_spawn_time {
		TheGame.special_spawn_accum_time = 0
		append(&TheGame.enemies, create_beefy_enemy())
	}
}

draw_enemy :: proc(enemy: ^Enemy) {
	rl.DrawRectangleRec(enemy.body, enemy.color)
}

