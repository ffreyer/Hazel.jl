using Revise, Hazel, LinearAlgebra, Printf


struct Sandbox2DLayer{
        AT <: Hazel.AbstractApplication
    } <: Hazel.AbstractLayer

    app::Ref{AT}
    name::String
    camera_controller::Hazel.OrthographicCameraController

    color::Vector{Float32}
    scene::Hazel.Scene
end

function Sandbox2DLayer(name = "Sandbox2D")
    # Build a basic Scene
    camera_controller = Hazel.OrthographicCameraController(
        1280/720, rotation = true
    )

    # # Square
    # robj1 = Hazel.Renderer2D.MoveableQuad(Vec2f0(-1.0), Vec2f0(1.5))
    # Hazel.rotateto!(robj1, 0.25pi)
    #
    # # Square
    texture = Hazel.Texture2D(joinpath(Hazel.assetpath, "textures", "Checkerboard.png"))
    # robj2 = Hazel.Renderer2D.Quad(
    #     Vec3f0(0, 0, .1), Vec3f0(1, 1, 0),
    #     u_texture = (0, texture), u_color = Vec4f0(1, 0.8, 0.7, 1.0),
    #     u_tilingfactor = 10f0
    # )
    quads = Hazel.Renderer2D.Quads()
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
        Vec3f0(0, -0.5, 1), Vec2f0(0.7),  color = Vec4f0(0.1, 0.3, 0.7, 1),
        texture = texture, rotation=45
    )
    push!(quads, quad1, quad2, quad3, quad4)
    scene = Hazel.Scene(camera_controller.camera, quads)

    Sandbox2DLayer(
        Ref{Hazel.BasicApplication}(),
        name,
        camera_controller,
        Float32[0.2, 0.4, 0.8, 1.0],
        scene
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
        Hazel.clear(Hazel.RenderCommand)
        Hazel.rotateby!(l.scene.render_objects[1].quads[2], Float32(5dt))
        Hazel.Renderer2D.submit(l.scene)
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

Hazel.destroy(l::Sandbox2DLayer) = Hazel.destroy(l.scene)
Hazel.string(l::Sandbox2DLayer) = l.name


# Hazel.enable_profiling()

app = Hazel.BasicApplication()
sl = Sandbox2DLayer()
push!(app, sl)
task = run(app)

# This allows running `julia Sandbox2D.jl` without it exiting immediately
# wait(task)
