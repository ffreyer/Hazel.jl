using Revise, Hazel, LinearAlgebra


struct Sandbox2DLayer{
        AT <: Hazel.AbstractApplication
    } <: Hazel.AbstractLayer

    app::Ref{AT}
    name::String
    camera_controller::Hazel.OrthographicCameraController

    # Temporary
    scene::Hazel.Scene
end

function Sandbox2DLayer(name = "Sandbox2D")
    # Build a basic Scene
    camera_controller = Hazel.OrthographicCameraController(
        1280/720, rotation = true
    )

    # Square
    robj1 = Hazel.Renderer2D.Quad(Vec2f0(-1.0), Vec2f0(1.5), u_color=Vec4f0(0))

    # What a dirty hack lol
    color = Float32[0.2, 0.4, 0.8, 1.0]
    @eval function Hazel.render(l::ImGuiLayer)
        Hazel.CImGui.ColorEdit4("Square color", $color)
        $(robj1)["u_color"] = Vec4f0($color...)
    end

    # Square
    texture = Hazel.Texture2D(joinpath(Hazel.assetpath, "textures", "Checkerboard.png"))
    Hazel.bind(texture)
    robj2 = Hazel.Renderer2D.Quad(Vec3f0(0, 0, .1), Vec3f0(1, 1, 0), u_texture=Int32(0))
    scene = Hazel.Scene(camera_controller.camera, robj1, robj2)

    Sandbox2DLayer(
        Ref{Hazel.BasicApplication}(),
        name,
        camera_controller,
        scene
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
    Hazel.Renderer2D.submit(l.scene)

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
