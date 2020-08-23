using Revise, Hazel, LinearAlgebra, Printf

include("particles.jl")


struct Sandbox2DLayer{
        AT <: Hazel.AbstractApplication
    } <: Hazel.AbstractLayer

    app::Ref{AT}
    name::String
    camera_controller::Hazel.OrthographicCameraController

    color::Vector{Float32}
    scene::Hazel.Scene
    particles::ParticleSystem
end

function Sandbox2DLayer(name = "Sandbox2D")
    # Build a basic Scene
    camera_controller = Hazel.OrthographicCameraController(
        1280/720, rotation = true
    )

    texture = Hazel.Texture2D(joinpath(Hazel.assetpath, "textures", "Checkerboard.png"))
    quad1 = Hazel.Renderer2D.Quad(
        Vec3f0(-1, -0.5, 0), Vec2f0(0.5), color = Vec4f0(0.7, 0.8, 1, 1)
    )
    quad2 = Hazel.Renderer2D.Quad(
        Vec3f0(+1, -0.5, 0), Vec2f0(1.0), color = Vec4f0(1, 0.8, 0.7, 1),
        texture = texture, tilingfactor = 10f0
    )
    quad3 = Hazel.Renderer2D.Quad(
        Vec3f0(0, 0.5, 1), Vec2f0(0.7),  color = Vec4f0(0.3, 0.8, 0.4, 1),
        texture = texture
    )
    quad4 = Hazel.Renderer2D.Quad(
        Vec3f0(0, -0.5, 2rand()), Vec2f0(0.7),  color = Vec4f0(0.1, 0.3, 0.7, 1),
        texture = texture, rotation=45
    )

    scene = Hazel.Scene(camera_controller.camera)
    push!(scene, quad1, quad2, quad3, quad4)

    # "Stress" test - goal: 100k+ @60
    for y in -5f0:0.1f0:5f0, x in -5f0:0.1f0:5f0
        quad = Hazel.Renderer2D.Quad(
            Vec3f0(x, y, 1), Vec2f0(0.45), 
            color = Vec4f0((x+5f0)/10f0, 0.4f0, (y+5f0)/10f0, 0.7f0)
        )
        push!(scene, quad)
    end

    robjs = Hazel.render_objects(scene)
    @info length(robjs)
    @info map(quads -> length(quads.quads), robjs)

    Sandbox2DLayer(
        Ref{Hazel.BasicApplication}(),
        name,
        camera_controller,
        Float32[0.2, 0.4, 0.8, 1.0],
        scene,
        ParticleSystem(camera_controller.camera)
    )
end


function Hazel.attach(l::Sandbox2DLayer, app::AbstractApplication)
    @info "Attaching $(typeof(app))"
    l.app[] = app
end


Hazel.@HZ_profile function Hazel.update!(l::Sandbox2DLayer, dt)
    app = l.app[]

    Hazel.@HZ_profile "Update camera" update!(l.camera_controller, app, dt)

    Hazel.@HZ_profile "Render Layer" begin
        Hazel.RenderCommand.clear()
        Hazel.rotateby!(l.scene.render_objects[1].quads[2], Float32(5dt))
        Hazel.Renderer2D.submit(l.scene)
    end

    Hazel.@HZ_profile "Render particles" begin
        if Hazel.mousebutton_pressed(app, MOUSE_BUTTON_LEFT)
            screen_pos = Hazel.mouse_pos(app)
            ww, wh = Hazel.window(app).properties.width, Hazel.window(app).properties.height
            pos = Hazel.position(l.camera_controller)
            sw, sh = Hazel.width(l.camera_controller), Hazel.height(l.camera_controller)
            x = (screen_pos[1] / ww - 0.5f0) * sw
            y = (0.5f0 - screen_pos[2] / wh) * sh
            particle_pos = Vec3f0(x, y, 2.0) .- pos
            for _ in 1:5
                emit!(l.particles, particle_pos, 0.005f0 * min(sw, sh))
            end
        end

        update!(l.particles, dt)
    end
    nothing
end

Hazel.@HZ_profile function Hazel.update!(gui_layer::Hazel.ImGuiLayer, sl::Sandbox2DLayer, dt)
    Hazel.CImGui.ColorEdit4("Square color", sl.color)
    # qvs = sl.scene.render_objects[1].vertices
    # qvs[3] = Hazel.Renderer2D.QuadVertex(qvs[3].position, Vec4f0(sl.color...), qvs[3].uv)
    nothing
end


Hazel.@HZ_profile function Hazel.handle!(l::Sandbox2DLayer, e::AbstractEvent)
    Hazel.handle!(l.camera_controller, e)
end

Hazel.destroy(l::Sandbox2DLayer) = (Hazel.destroy(l.particles); Hazel.destroy(l.scene))
Hazel.string(l::Sandbox2DLayer) = l.name


# Hazel.enable_profiling()
begin
    app = Hazel.BasicApplication()
    try
        sl = Sandbox2DLayer()
        push!(app, sl)
    finally
        task = run(app)
    end
    nothing
end

# This allows running `julia Sandbox2D.jl` without it exiting immediately
# wait(task)
