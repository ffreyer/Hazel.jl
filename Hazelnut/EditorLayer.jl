using Hazel: AbstractLayer, AbstractApplication
using Hazel: Framebuffer, BasicApplication
using Hazel: Texture2D, RGBA, N0f8
using Hazel: @HZ_profile
using Hazel: RenderCommand
using Hazel: CImGui, ImGuiLayer

using LinearAlgebra, Printf

include("Panels/SceneHierarchy.jl")

mutable struct EditorLayer <: AbstractLayer
    framebuffer::Framebuffer
    cam::Hazel.EditorCamera
    scene::Scene
    spritesheet::RegularSpriteSheet

    # Entities
    quad::Quad
    camera::Camera
    camera2::Camera

    p::SceneHierarchyPanel

    viewport_focused::Bool


    function EditorLayer()
        layer = new()

        # 2560 x 1664 ~ 20x13 Tiles @ 128x128
        spritesheet = layer.spritesheet = RegularSpriteSheet(joinpath(
            Hazel.assetpath, "textures/kenneyrpgpack/Spritesheet/RPGpack_sheet_2X.png"
        ), Nx=20, Ny=13)
    
        scene = layer.scene = Scene()
    
        layer.quad = addQuad!(scene, 
            position = Vec3f0(0, 0, -0.1), 
            color = Vec4f0(1, 0.5, 0.5, 1), 
            name = "Red Square"
        )
        addQuad!(scene, 
            position = Vec3f0(0, 0.1, -0.05), 
            color = Vec4f0(0.5, 1.0, 0.5, 1), 
            name = "Green Square"
        )
    
        camera = layer.camera = Camera(scene, name = "Orthographic Camera")
        script = ScriptComponent(
            update! = (app, entity, ts) -> begin
                offset = -Hazel.delta(ts) * Vec3f0(
                    keypressed(app, Hazel.KEY_D) - keypressed(app, Hazel.KEY_A),
                    keypressed(app, Hazel.KEY_W) - keypressed(app, Hazel.KEY_S),
                    0
                )
                moveby!(Camera(entity), offset)
            end
        )
        push!(camera, script)
        camera2 = layer.camera2 = Camera(scene, name = "Clip Space Camera", height = 2f0)
        activate!(camera)
    
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
    
        # tilemap = string2map("WWWW", 4, 1, spritesheet)
    
        for i in 1:size(tilemap, 1), j in 1:size(tilemap, 2)
            addQuad!(scene, position = Vec3f0(i-12, j-7, 0), texture = tilemap[i, j])
        end
    
        push!(scene, Hazel.Stage(:PreRender, [Hazel.RunScript(), Hazel.CameraUpdate()]))
        addBatchRenderingStage!(scene)
    
        layer.p = SceneHierarchyPanel(scene)
        layer.viewport_focused = false

        layer
    end    
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
    @info "Attaching EditorLayer to $(typeof(app))"
    l.framebuffer = Hazel.Framebuffer(size(Hazel.window(app))...)
    id = l.framebuffer.t_id
    Hazel.CImGui.OpenGLBackend.g_ImageTexture[Int(id)] = id
    l.cam = Hazel.EditorCamera(viewport = Vec2f0(size(l.framebuffer)))
end


@HZ_profile function Hazel.update!(app, l::EditorLayer, ts)
    update!(app, l.cam, ts)

    # Clear window
    RenderCommand.clear()

    Hazel.bind(l.framebuffer)
    # Clear framebuffer
    RenderCommand.clear()

    @HZ_profile "Render Layer" begin
        Hazel.update_editor!(app, l.scene, l.cam, ts)
    end
    Hazel.unbind(l.framebuffer)

    nothing
end

@HZ_profile function Hazel.update!(app, gui_layer::ImGuiLayer, sl::EditorLayer, ts)
    if CImGui.BeginMainMenuBar()
        if CImGui.BeginMenu("File")
            if CImGui.MenuItem("New")
                sl.scene = Hazel.Scene()
                sl.p.scene = sl.scene
                push!(sl.scene, Hazel.Stage(:PreRender, [Hazel.RunScript(), Hazel.CameraUpdate()]))
                addBatchRenderingStage!(sl.scene)
            end
            if CImGui.MenuItem("Serialize")
                Hazel.serialize("example.hazel", sl.scene)
            end
            if CImGui.MenuItem("Deserialize")
                sl.scene = Hazel.deserialize("example.hazel")
                sl.p.scene = sl.scene
                # TODO: Maybe activate those on Entity creation?
                push!(sl.scene, Hazel.Stage(:PreRender, [Hazel.RunScript(), Hazel.CameraUpdate()]))
                addBatchRenderingStage!(sl.scene)
            end
            if CImGui.MenuItem("Exit")
                destroy(app)
            end
            CImGui.EndMenu()
        end
        CImGui.EndMainMenuBar()
    end

    CImGui.PushStyleVar(CImGui.ImGuiStyleVar_WindowPadding, (0, 0))
    CImGui.Begin("Viewport")
    sl.viewport_focused = CImGui.IsWindowFocused()
    gui_layer.consume_events = !(sl.viewport_focused) && !CImGui.IsWindowHovered()
    window_size = CImGui.GetContentRegionAvail()
    w = trunc(UInt32, window_size.x); h = trunc(UInt32, window_size.y)
    if (w, h) != size(sl.framebuffer)
        resize!(sl.framebuffer, w, h)
        Hazel.resize_viewport!(sl.scene, w, h)
        Hazel.resize_viewport!(sl.cam, w, h)
        update!(app, sl, ts)
    end
    CImGui.Image(Ptr{Cvoid}(Int(sl.framebuffer.t_id)), window_size, (0, 1), (1, 0))
    CImGui.End()
    CImGui.PopStyleVar()

    render!(sl.p)

    nothing
end


@HZ_profile function Hazel.handle!(l::EditorLayer, e::AbstractEvent)
    Hazel.handle!(l.cam, e)
    false
end

function destroy(l::EditorLayer)
    destroy(l.scene)
    destroy(l.framebuffer[])
end

Base.string(l::EditorLayer) = l.name