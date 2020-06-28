using Revise, Hazel, LinearAlgebra, Printf


struct ProfileResult
    name::String
    time::Float64
end

struct Sandbox2DLayer{
        AT <: Hazel.AbstractApplication
    } <: Hazel.AbstractLayer

    app::Ref{AT}
    name::String
    camera_controller::Hazel.OrthographicCameraController

    profile_results::Vector{ProfileResult}

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
    color = Float32[0.2, 0.4, 0.8, 1.0]
    profile_results = ProfileResult[]
    @eval function Hazel.render(l::ImGuiLayer)
        Hazel.CImGui.ColorEdit4("Square color", $color)
        $(robj1)["u_color"] = Vec4f0($color...)

        True = true
        Hazel.CImGui.@c Hazel.CImGui.ShowDemoWindow(&True)

        for result in $profile_results
            s = @sprintf("%s  %0.3f", result.name, 1000result.time)
            Hazel.CImGui.TextColored(Hazel.CImGui.ImVec4(1,1,1, 1), s)
        end
        empty!($profile_results)

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
        profile_results,
        scene
    )
end


function Hazel.attach(l::Sandbox2DLayer, app::AbstractApplication)
    @info "Attaching $(typeof(app))"
    l.app[] = app
end



function Hazel.update!(l::Sandbox2DLayer, dt)
    t = time()

    app = l.app[]

    t2 = time()
    update!(l.camera_controller, app, dt)
    t3 = time()
    Hazel.clear(Hazel.RenderCommand)
    Hazel.Renderer2D.submit(l.scene)

    push!(l.profile_results, ProfileResult("update!(Sandbox2DLayer)", time()-t))
    push!(l.profile_results, ProfileResult("update!(CameraController)", t3-t2))

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
