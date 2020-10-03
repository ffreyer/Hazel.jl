# https://github.com/TheCherno/OneHourParticleSystem/tree/master/OpenGL-Sandbox/src

using Hazel

mutable struct Particle
    quad::Hazel.Renderer2D.Quad

    velocity::Vec2f0

    start_color::Vec4f0
    stop_color::Vec4f0
    start_size::Float32
    stop_size::Float32

    life_time::Float32
    life_remaining::Float32
end
rand_unit_vector() = (phi = 2pi * rand(); Vec2f0(cos(phi), sin(phi)))
function Particle(;
        position = 0.01f0 * rand(Float32) * rand_unit_vector(), 
        velocity = 0.05f0 * sqrt(rand()) * rand_unit_vector(),
        start_color = Vec4f0(0.9, 0.2, 0.2, 1.0), 
        stop_color = Vec4f0(0.1, 0.1, 0.6, 1.0),
        rotation = 360f0 * rand(Float32),  
        start_size = 0.01f0, stop_size = 0.01f0 + 0.01rand(Float32),
        life_time = 1f0+4rand(), life_remaining = life_time, 
        active = false, kwargs...
    )
    quad = Hazel.Renderer2D.Quad(
        Vec3f0(position..., 0f0), Vec2f0(start_size), 
        rotation=rotation, color = start_color, visible=active;
        kwargs...
    )
    Particle(
        quad,
        velocity, 
        start_color, stop_color,
        start_size, stop_size,
        life_time, life_remaining
    )
end

mutable struct ParticleSystem
    pool::Vector{Particle}
    scene::Scene
    idx::Int64
end

function ParticleSystem(camera; kwargs...)
    pool = [Particle(; kwargs...) for _ in 1:1000]
    
    scene = Scene(camera)
    push!(scene, (particle.quad for particle in pool)...)

    ParticleSystem(pool, scene, 1)
end

lerp(t, start, stop) = stop + t * (start - stop)

function Hazel.update!(ps::ParticleSystem, dt)
    # Update particles
    for (i, particle) in enumerate(ps.pool)
        particle.quad.visible || continue
        
        particle.life_remaining <= 0 && (particle.quad.visible = false; continue)
        particle.life_remaining -= dt
        
        particle.quad.position += Vec3f0((particle.velocity * dt)..., 0f0)
        particle.quad.rotation += dt 
        s = lerp(particle.life_remaining / particle.life_time, particle.start_size, particle.stop_size)
        particle.quad.scale = Vec3f0(s, s, 1f0)
        Hazel.Renderer2D.setcolor!(
            particle.quad, 
            lerp(particle.life_remaining / particle.life_time, particle.start_color, particle.stop_color)
        )
        Hazel.Renderer2D.recalculate!(particle.quad)
    end
    # Render particles
    Hazel.Renderer2D.submit(ps.scene)
end

function emit!(ps::ParticleSystem, pos::Vec3f0, scale::Float32)
    p = ps.pool[ps.idx]
    Hazel.Renderer2D.moveto!(p.quad, 
        pos + rand(Float32)^2 * scale * Vec3f0(rand_unit_vector()..., 0f0)
    )
    p.quad.visible = true
    p.life_remaining = p.life_time
    p.start_size = scale
    p.stop_size = scale * (1f0 + rand(Float32))

    # println(p)
    ps.idx = mod1(ps.idx+1, length(ps.pool))
end
