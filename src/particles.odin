package main
import "core:math/rand"
import rl "vendor:raylib"

Particle :: struct {
	position:         Vector2,
	size:             Vector2,
	color:            rl.Color,
	current_lifetime: f32,
	velocity:         Vector2,
	active:           bool,
}


ParticleEmitter :: struct {
	position:         Vector2,
	// rand stuff
	min_velocity:     Vector2,
	max_velocity:     Vector2,
	min_size:         Vector2,
	max_size:         Vector2,
	min_amount:       int,
	max_amount:       int,
	//
	spread:           Vector2,
	fire_rate:        f32,
	lifetime:         f32,
	emitter_lifetime: f32,
	forever:          bool,
	texture_name:     Texture_Name,
	particles:        [dynamic]Particle,
	active:           bool,
	color:            rl.Color,
}


create_emitter :: proc(
	position: Vector2,
	velocity: Vector2,
	spread: Vector2,
	size: Vector2,
	fire_rate: f32,
	lifetime: f32,
	amount: int = 4,
	randomness: f32 = 0.0,
	texture_name: Texture_Name = .None,
) -> ParticleEmitter {
	emitter: ParticleEmitter
	emitter.active = true
	emitter.position = position
	emitter.spread = spread
	emitter.lifetime = lifetime
	emitter.fire_rate = fire_rate
	emitter.texture_name = texture_name

	if randomness == 0.0 {
		emitter.min_velocity = velocity
		emitter.max_velocity = velocity

		emitter.min_size = size
		emitter.max_size = size

		emitter.min_amount = amount
		emitter.max_amount = amount

	} else {
		emitter.min_velocity = {
			velocity.x != 0.0 ? velocity.x - randomness : 0.0,
			velocity.y != 0.0 ? velocity.y - randomness : 0.0,
		}
		emitter.max_velocity = {
			velocity.x != 0.0 ? velocity.x + randomness : 0.0,
			velocity.y != 0.0 ? velocity.y + randomness : 0.0,
		}

		emitter.min_size = size - randomness
		emitter.max_size = size + randomness

		emitter.min_amount = amount - auto_cast randomness
		emitter.max_amount = amount + auto_cast randomness
	}


	return emitter

}

import "core:math"
update_and_render_particles :: proc(dt: f32) {
	set_z_layer(.particles)
	for &emitter in game.particle_emitters {
		if !emitter.forever {
			emitter.emitter_lifetime -= dt
			if emitter.emitter_lifetime <= 0.0 {
				emitter.active = false
			}
		}

		if run_every_seconds(emitter.fire_rate) || emitter.fire_rate == 0.0 {
			for i := 0; i < emitter.max_amount; i += 1 {
				p: Particle
				p.active = true
				p.current_lifetime = emitter.lifetime
				p.color = emitter.color
				p.size = random_ranged_vector2(emitter.min_size, emitter.max_size)
				p.velocity = random_ranged_vector2(emitter.min_velocity, emitter.max_velocity)
				p.position =
					emitter.position + random_ranged_vector2(-emitter.spread, emitter.spread)

				append(&emitter.particles, p)
			}
		}

		for &particle in emitter.particles {
			particle.current_lifetime -= dt
			if particle.current_lifetime <= 0.0 {
				particle.active = false
			}

			particle.position += particle.velocity * dt


			// Calculate t (0 to 1, where 1 = full lifetime, 0 = no lifetime left)
			t: f32 = particle.current_lifetime / emitter.lifetime
			alpha: f32 = auto_cast math.lerp(f32(1.0), f32(0.0), f32(1.0) - t)
			particle.color.a = u8(alpha * 255)


			if emitter.texture_name == .None {
				draw_rect(particle.position, particle.size, particle.color)
			} else {
				draw_sprite(particle.position, emitter.texture_name, particle.size, particle.color)

			}

		}


		cleanup_base_entity(&emitter.particles)
	}

	cleanup_base_entity(&game.particle_emitters)
}
