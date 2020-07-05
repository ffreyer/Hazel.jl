using Revise, Hazel, LinearAlgebra, Printf


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

    # TODO
    # What a dirty hack lol
    # Just attach this to this layer ...
    # There is no reason for this to be attached to the ImGui layer, is there?
    # Well, actually there is - we need Begin and End around it
    # maybe in ImGuiLayer update!():
    # for layer in l.app.layerstack
    #     renderImGui(l, layer)
    # end
    # or set callbacks? But that's not very dispatch-y
    color = Float32[0.2, 0.4, 0.8, 1.0]
    @eval function Hazel.render(l::ImGuiLayer)
        Hazel.CImGui.ColorEdit4("Square color", $color)
        $(robj1)["u_color"] = Vec4f0($color...)

        True = true
        Hazel.CImGui.@c Hazel.CImGui.ShowDemoWindow(&True)

        nothing
    end

    # Square
    texture = Hazel.Texture2D(joinpath(Hazel.assetpath, "textures", "Checkerboard.png"))
    robj2 = Hazel.Renderer2D.Quad(
        Vec3f0(0, 0, .1), Vec3f0(1, 1, 0),
        u_texture = (0, texture), u_color = Vec4f0(1, 0.8, 0.7, 1.0)
    )
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


Hazel.@HZ_profile function Hazel.update!(l::Sandbox2DLayer, dt)
    app = l.app[]

    Hazel.@HZ_profile "Update camera" update!(l.camera_controller, app, dt)

    Hazel.@HZ_profile "Render Layer" begin
        Hazel.clear(Hazel.RenderCommand)
        Hazel.Renderer2D.submit(l.scene)
    end
    nothing
end


Hazel.@HZ_profile function Hazel.handle!(l::Sandbox2DLayer, e::AbstractEvent)
    Hazel.handle!(l.camera_controller, e)
end

Hazel.destroy(l::Sandbox2DLayer) = Hazel.destroy(l.scene)
Hazel.string(l::Sandbox2DLayer) = l.name


Hazel.enable_profiling()

app = Hazel.BasicApplication()
push!(app, Sandbox2DLayer())
task = run(app)
