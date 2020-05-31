using Hazel, LinearAlgebra


struct Sandbox2DLayer{
        AT <: Hazel.AbstractApplication
    } <: Hazel.AbstractLayer

    app::Ref{AT}
    name::String
    camera_controller::Hazel.OrthographicCameraController

    # Temporary
    scene::Hazel.Scene
    color::Vector{Float32}
end

function Sandbox2DLayer(name = "Sandbox2D")
    # Build a basic Scene
    camera_controller = Hazel.OrthographicCameraController(
        1280/720, rotation = true
    )

    # Square
    scene = Hazel.Scene(
        camera_controller.camera,
        Hazel.Renderer2D.Quad(Vec2f0(-0.5), Vec2f0(1))
    )

    # What a dirty hack lol
    color = Float32[0.2, 0.4, 0.8, 1.0]
    @eval function Hazel.render(l::ImGuiLayer)
        Hazel.CImGui.ColorEdit4("Square color", $color)
    end


    Sandbox2DLayer(
        Ref{Hazel.BasicApplication}(),
        name,
        camera_controller,
        scene, color
    )
end


function Hazel.attach(l::Sandbox2DLayer, app::AbstractApplication)
    @info "Attaching $(typeof(app))"
    l.app[] = app
end



function Hazel.update!(l::Sandbox2DLayer, dt)
    app = l.app[]

    update!(l.camera_controller, app, dt)


    Hazel.clear(Hazel.RenderCommand)

    # Hazel.bind(l.robj)
    # Hazel.upload!(l.robj.shader, u_color = Vec4f0(l.color))
    # Hazel.submit(
    #     Hazel.Renderer(), l.robj,
    #     Hazel.projection_view(l.camera_controller.camera),
    #     Mat4f0(I)
    # )
    Hazel.Renderer2D.submit(l.scene, u_color = Vec4f0(l.color))

    nothing
end


function Hazel.handle!(l::Sandbox2DLayer, e::AbstractEvent)
    Hazel.handle!(l.camera_controller, e)
end

Hazel.destroy(l::Sandbox2DLayer) = Hazel.destroy(l.scene)
Hazel.string(l::Sandbox2DLayer) = l.name


app = Hazel.BasicApplication()
push!(app, Sandbox2DLayer())
task = run(app)
