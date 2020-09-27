using Hazel, LinearAlgebra, Printf

include("particles.jl")


struct Sandbox2DLayer{
        AT <: Hazel.AbstractApplication
    } <: Hazel.AbstractLayer

    app::Ref{AT}
    name::String
    camera_controller::Hazel.OrthographicCameraController
    framebuffer::Ref{Hazel.Framebuffer}

    color::Vector{Float32}
    scene::Hazel.Scene
    scene2::Hazel.Scene
    particles::ParticleSystem
    spritesheet::Hazel.RegularSpriteSheet{Hazel.Texture2D{Hazel.RGBA{Hazel.N0f8}}, Float32}
end

function Sandbox2DLayer(name = "Sandbox2D")
    # Build a basic Scene
    camera_controller = Hazel.OrthographicCameraController(
        1280/720, rotation = true
    )
    Hazel.zoom!(camera_controller, 10f0)

    # 2560 x 1664 ~ 20x13 Tiles @ 128x128
    spritesheet = Hazel.RegularSpriteSheet(joinpath(
        Hazel.assetpath, "textures/kenneyrpgpack/Spritesheet/RPGpack_sheet_2X.png"
    ), Nx=20, Ny=13)

    scene2 = Hazel.Scene(camera_controller.camera)
    # push!(scene,
    #     # Hazel.Renderer2D.Quad(Vec3f0(-2, 0, 9), Vec2f0(1), texture = spritesheet[1, 12]), 
    #     # Hazel.Renderer2D.Quad(Vec3f0(-1, 0, 9), Vec2f0(1), texture = spritesheet[2, 12]), 
    #     # Hazel.Renderer2D.Quad(Vec3f0(0), Vec2f0(1), texture = spritesheet[8, 6]), 
    #     Hazel.Renderer2D.Quad(Vec3f0(1, 0.5, 1), Vec2f0(1, 2), texture = spritesheet[1, 2:3])
    # )

    
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
    # let
    #     char2tilecoord = Dict(
    #         'W' => spritesheet[12, 12], 'D' => spritesheet[7, 12],
    #         '\\' => spritesheet[9, 1]
    #     )
    #     map_input = """
    #     WWWW WWWW WWWW WWWW WWWW WWWW
    #     WWWW WWWW WWWW WWWW WWWW WWWW
    #     WWWW WWWW GGGG GGWW WWWW WWWW
    #     WWWW WGGG GGGG GGWG GWWW WWWW
    #     WWWW GGGG GGGG GWWG GGGW WWWW
    #     WWWW GGGG GGGW WWGG GGGG WWWW
    #     WWWG GGGG GGGW WWGG GGGG WWWW
    #     WWWG GGGG GGGG WGGG GGGG GWWW
    #     WWWG GGGG GGGG GGGG GGGG GWWW
    #     WWWW GGGG GGGG GGGG GGGG GWWW
    #     WWWW GGGG GGGG GGGG GGGG WWWW
    #     WWWW WGGG GGGG GGGG GGGG WWWW
    #     WWWW WWWG GWWW WWWW GGGW WWWW
    #     WWWW WWWW WWWW WWWW WWWW WWWW"""
    #     clean = replace(replace(map_input, ' ' => ""), '\n' => "")
    #     tilemap = map(c -> haskey(char2tilecoord, c) ? char2tilecoord[c] : char2tilecoord['\\'], collect(clean))
    #     reshape(tilemap, (24, 14))
    # end
    for i in 1:size(tilemap, 1), j in 1:size(tilemap, 2)
        push!(scene2, Hazel.Renderer2D.Quad(
            Vec3f0(i-12, j-7, 0), Vec2f0(1), texture = tilemap[i, j]
        ))
    end

    ps = ParticleSystem(
        camera_controller.camera,
        texture = spritesheet[3, 4]
    )

    Sandbox2DLayer(
        Ref{Hazel.BasicApplication}(),
        name,
        camera_controller,
        Ref{Hazel.Framebuffer}(),
        Float32[0.2, 0.4, 0.8, 1.0],
        scene2, scene2,
        ps,
        spritesheet
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


function Hazel.attach(l::Sandbox2DLayer, app::AbstractApplication)
    @info "Attaching $(typeof(app))"
    l.app[] = app
    l.framebuffer[] = Hazel.Framebuffer(size(Hazel.window(app))...)
    id = l.framebuffer[].t_id
    Hazel.CImGui.OpenGLBackend.g_ImageTexture[Int(id)] = id
end


Hazel.@HZ_profile function Hazel.update!(l::Sandbox2DLayer, dt)
    app = l.app[]

    Hazel.@HZ_profile "Update camera" update!(l.camera_controller, app, dt)
    
    Hazel.bind(l.framebuffer[])
    Hazel.RenderCommand.clear()

    Hazel.@HZ_profile "Render particles" begin
        if Hazel.mousebutton_pressed(app, MOUSE_BUTTON_LEFT)
            screen_pos = Hazel.mouse_pos(app)
            ww, wh = Hazel.window(app).properties.width, Hazel.window(app).properties.height
            pos = Hazel.position(l.camera_controller)
            sw, sh = Hazel.width(l.camera_controller), Hazel.height(l.camera_controller)
            x = (screen_pos[1] / ww - 0.5f0) * sw
            y = (0.5f0 - screen_pos[2] / wh) * sh
            particle_pos = Vec3f0(x, y, -0.5) .- pos
            for _ in 1:5
                emit!(l.particles, particle_pos, 0.05f0 * min(sw, sh))
            end
        end

        update!(l.particles, dt)
    end

    Hazel.@HZ_profile "Render Layer" begin
        # Hazel.rotateby!(l.scene.render_objects[1].quads[2], Float32(5dt))
        Hazel.Renderer2D.submit(l.scene)
        Hazel.Renderer2D.submit(l.scene2)
    end
    Hazel.unbind(l.framebuffer[])

    nothing
end

Hazel.@HZ_profile function Hazel.update!(gui_layer::Hazel.ImGuiLayer, sl::Sandbox2DLayer, dt)
    # Hazel.CImGui.ColorEdit4("Square color", sl.color)
    # qvs = sl.scene.render_objects[1].vertices
    # qvs[3] = Hazel.Renderer2D.QuadVertex(qvs[3].position, Vec4f0(sl.color...), qvs[3].uv)
    Hazel.CImGui.Begin("Framebuffer")
    Hazel.CImGui.Image(Ptr{Cvoid}(Int(sl.framebuffer[].t_id)), (320f0, 180f0))
    Hazel.CImGui.End()
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
    # Hazel.disable_vsync(Hazel.window(app))
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