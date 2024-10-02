package main

import rl "vendor:raylib"

BASE_SPAWN_TIME :: 1.75

Enemy :: struct {
	body:      rl.Rectangle,
	color:     rl.Color,
	health:    f32,
	speed:     f32,
	damage:    i32,
	exp_value: u32,
}

create_basic_enemy :: proc() -> Enemy {
	spawn_x := rl.GetRandomValue(15, WIDTH - 35)
	return Enemy {
		body = rl.Rectangle{f32(spawn_x), 0, 25, 25},
		color = rl.RED,
		health = 25,
		speed = 175,
		damage = 2,
		exp_value = 10,
	}
}

create_beefy_enemy :: proc() -> Enemy {
	spawn_x := rl.GetRandomValue(20, WIDTH - 120)
	return Enemy {
		body = rl.Rectangle{f32(spawn_x), 0, 100, 75},
		color = rl.YELLOW,
		health = 200,
		speed = 70,
		damage = 50,
		exp_value = 45,
	}
}

create_speedy_enemy :: proc() -> Enemy {
	spawn_x := rl.GetRandomValue(30, WIDTH - 30)
	return Enemy {
		body = rl.Rectangle{f32(spawn_x), 0, 15, 45},
		color = rl.BLUE,
		health = 15,
		speed = 375,
		damage = 1,
		exp_value = 20,
	}
}

tick_enemy :: proc(enemy: ^Enemy) -> (alive: bool, killed_by_player: bool) {
	if enemy.body.y >= HEIGHT {
		TheGame.player.cur_health -= enemy.damage
		return false, false
	} else if enemy.health <= 0 {
		return false, true
	} else {
		enemy.body.y += enemy.speed * rl.GetFrameTime()
		return true, false
	}
}

tick_enemies :: proc() {
	#reverse for &enemy, index in TheGame.enemies {
		alive, killed_by_player := tick_enemy(&enemy)
		if alive {
			draw_enemy(&enemy)
		} else {
			if killed_by_player {
				gain_exp_player(enemy.exp_value)
			}
			unordered_remove(&TheGame.enemies, index)
		}
	}

	special_spawn_time := TheGame.spawn_time * 7
	frame_time := rl.GetFrameTime()

	TheGame.spawn_accum_time += frame_time
	TheGame.special_spawn_accum_time += frame_time
	TheGame.spawn_increase_timer += frame_time

	if TheGame.spawn_accum_time >= TheGame.spawn_time {
		TheGame.spawn_accum_time = 0
		append(&TheGame.enemies, create_basic_enemy())
	}
	if TheGame.special_spawn_accum_time >= special_spawn_time {
		TheGame.special_spawn_accum_time = 0
		append(&TheGame.enemies, create_beefy_enemy())
		append(&TheGame.enemies, create_speedy_enemy())
	}

	// every minute 10% faster spawns
	should_increase_spawn_rate := u32(TheGame.spawn_increase_timer) >= 60
	if should_increase_spawn_rate {
		TheGame.spawn_time *= .90
		TheGame.spawn_increase_timer = 0
	}
}

draw_enemy :: proc(enemy: ^Enemy) {
	rl.DrawRectangleRec(enemy.body, enemy.color)
}
