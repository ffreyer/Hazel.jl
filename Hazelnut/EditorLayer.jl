using Hazel: AbstractLayer, AbstractApplication
using Hazel: Framebuffer, BasicApplication
using Hazel: Texture2D, RGBA, N0f8
using Hazel: @HZ_profile
using Hazel: RenderCommand
using Hazel: CImGui, ImGuiLayer

using LinearAlgebra, Printf

struct EditorLayer{AT <: AbstractApplication} <: AbstractLayer
    app::Ref{AT}
    camera_controller::OrthographicCameraController
    framebuffer::Ref{Framebuffer}

    color::Vector{Float32}
    scene::Scene
    scene2::Scene
    spritesheet::RegularSpriteSheet{Texture2D{RGBA{N0f8}}, Float32}

    viewport_focused::Ref{Bool}
end

function EditorLayer()
    # Build a basic Scene
    camera_controller = OrthographicCameraController(1280/720, rotation = true)
    zoom!(camera_controller, 10f0)

    # 2560 x 1664 ~ 20x13 Tiles @ 128x128
    spritesheet = RegularSpriteSheet(joinpath(
        Hazel.assetpath, "textures/kenneyrpgpack/Spritesheet/RPGpack_sheet_2X.png"
    ), Nx=20, Ny=13)

    scene2 = Scene(camera_controller.camera)
    
    tilemap = string2map("""
    WWWW WWWW WWWW WWWW WWWW WWWW
    WWWW WWWW WWWW WWWW WWWW WWWW
    WWWW WWWW GGGG GGWW WWWW WWWW
    WWWW WGGG GGGG GGWG GWWW WWWW
    WWWW GGGG GGGG GWWG GGGW WWWW
    WWWW GGGG GGGW WWGG GGGG WWWW
    WWWG GGGG GGGW WWGG GGGG WWWW
    WWWG GGGG GGGG WGGG GGGG GWWW
    WWWG GGGG GGGG GGGG GGGG GWWW
    WWWW GGGG GGGG GGGG GGGG GWWW
    WWWW GGGG GGGG GGGG GGGG WWWW
    WWWW WGGG GGGG GGGG GGGG WWWW
    WWWW WWWG GWWW WWWW GGGW WWWW
    WWWW WWWW WWWW WWWW WWWW WWWW""", 24, 14, spritesheet)

    for i in 1:size(tilemap, 1), j in 1:size(tilemap, 2)
        push!(scene2, Renderer2D.Quad(
            Vec3f0(i-12, j-7, 0), Vec2f0(1), texture = tilemap[i, j]
        ))
    end


    EditorLayer(
        Ref{BasicApplication}(),
        camera_controller,
        Ref{Framebuffer}(),
        Float32[0.2, 0.4, 0.8, 1.0],
        scene2, scene2,
        spritesheet,
        Ref(false)
    )
end


function string2map(chars::String, Lx, Ly, spritesheet)
    char2sprite = Dict(
        'W' => (12, 12), 'D' => (7, 12), 'G' => (2, 12), '\\' => (9, 1)
    )
    clean = replace(replace(chars, ' ' => ""), '\n'=>"")
    charmap = reshape(collect(clean), (Lx, Ly))
    tilemap = Matrix{typeof(spritesheet[1, 1])}(undef, Lx, Ly)
    for x in 1:size(charmap, 1), y in 1:size(charmap, 2)
        c = charmap[x, y]
        sprite_idx = char2sprite[c]
        if c in "W"
            for dx in -1:1, dy in -1:1
                abs(dx) + abs(dy) == 1 || continue
                0 < x+dx < Lx || continue
                0 < y+dy < Ly || continue
                if c != charmap[x+dx, y+dy]
                    sprite_idx = sprite_idx .+ (dx, dy)
                end
            end
        end
        tilemap[x, y] = spritesheet[sprite_idx...]
    end

    tilemap
end


function Hazel.attach(l::EditorLayer, app::AbstractApplication)
    @info "Attaching $(typeof(app))"
    l.app[] = app
    l.framebuffer[] = Hazel.Framebuffer(size(Hazel.window(app))...)
    id = l.framebuffer[].t_id
    Hazel.CImGui.OpenGLBackend.g_ImageTexture[Int(id)] = id
end


@HZ_profile function Hazel.update!(l::EditorLayer, dt)
    app = l.app[]

    @HZ_profile "Update camera" update!(l.camera_controller, app, dt)
    
    # Clear window
    RenderCommand.clear()
    Hazel.bind(l.framebuffer[])
    # Clear framebuffer
    RenderCommand.clear()

    @HZ_profile "Render Layer" begin
        Renderer2D.submit(l.scene)
        Renderer2D.submit(l.scene2)
    end
    Hazel.unbind(l.framebuffer[])

    nothing
end

@HZ_profile function Hazel.update!(gui_layer::ImGuiLayer, sl::EditorLayer, dt)
    CImGui.PushStyleVar(CImGui.ImGuiStyleVar_WindowPadding, (0, 0))
    CImGui.Begin("Viewport")
    l.viewport_focused[] = CImGui.IsWindowFocus()
    gui_layer.consume_events = !(l.viewport_focused[]) || !CimGui.IsWindowHovered()
    window_size = CImGui.GetContentRegionAvail()
    if window_size != size(sl.framebuffer[])
        w = trunc(UInt32, window_size.x); h = trunc(UInt32, window_size.y)
        resize!(sl.framebuffer[], w, h)
        resize!(sl.camera_controller, w, h)
        update!(sl, 0.0)
    end
    CImGui.Image(Ptr{Cvoid}(Int(sl.framebuffer[].t_id)), window_size, (0, 1), (1, 0))
    CImGui.End()
    CImGui.PopStyleVar()
    nothing
end


@HZ_profile function Hazel.handle!(l::EditorLayer, e::AbstractEvent)
    if l.viewport_focused[]
        handle!(l.camera_controller, e)
    end
end

Base.string(l::EditorLayer) = l.name