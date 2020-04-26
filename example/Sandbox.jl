using Hazel

# implement Layer
struct ExampleLayer{
        ST <: Hazel.AbstractScene,
        AT <: Hazel.AbstractApplication
    } <: Hazel.AbstractLayer
    app::Ref{AT}

    name::String
    renderer::Hazel.Renderer
    scene::ST
    shader_library::Hazel.ShaderLibrary

    square_robj::Hazel.RenderObject
    triangle_robj::Hazel.RenderObject
    texture_robj::Hazel.RenderObject #tex_shader::Hazel.Shader
    texture::Hazel.Texture2D
    alpha_texture::Hazel.Texture2D

    camera::Hazel.OrthographicCamera
    cam_translation_speed::Float32
    cam_rotation_speed::Float32

    square_position::Vector{Float32} # mutable struct w/ Vec3f0 might be better
    square_translation_speed::Float32
    square_color::Vector{Float32}
end

function ExampleLayer(name::String = "Example")
    # Build a basic Scene
    camera = Hazel.OrthographicCamera(-1.6f0, 1.6f0, -0.9f0, 0.9f0)
    scene = Hazel.Scene(camera)
    shader_library = Hazel.ShaderLibrary()


    # Render a Rectangle in the background (push first)
    # positions
    vertices = Float32[
        -0.5, -0.5, 0.0,   0.0, 0.0,
         0.5, -0.5, 0.0,   1.0, 0.0,
        -0.5,  0.5, 0.0,   0.0, 1.0,
         0.5,  0.5, 0.0,   1.0, 1.0
    ]
    # vertices contains "positions" of type "Point3f0"
    # (Float32 3 component vectors)
    layout = Hazel.BufferLayout(position = Point3f0, uv = Point2f0)
    # vertices + layout are bundled
    vertex_buffer = Hazel.VertexBuffer(vertices, layout)
    # indices to connect vertices (draw two triangles to make rectangle)
    index_buffer = Hazel.IndexBuffer(UInt32[0, 1, 2, 1, 2, 3])

    # Basic shader that takes positions and a matrix to draw
    # a flat color object
    vertex_source = """
    #version 330 core

    layout(location = 0) in vec3 a_position; // a = attributed

    uniform mat4 u_projection_view;
    uniform mat4 u_transform;

    out vec3 v_position; // v = varying

    void main(){
        v_position = a_position;
        gl_Position = u_projection_view * u_transform * vec4(a_position, 1.0);
    }
    """
    fragment_source = """
    #version 330 core

    layout(location = 0) out vec4 color; // a = attributed
    uniform vec3 u_color;
    in vec3 v_position;

    void main(){
        color = vec4(u_color, 1.0);
    }
    """

    # # Combine everything into a renderobject. A Renderobject has all the
    # # information necessary to be rendered.
    square_robj = Hazel.RenderObject(
        Hazel.Shader("SquareShader", vertex_source, fragment_source),
        Hazel.VertexArray(vertex_buffer, index_buffer)
    )
    push!(shader_library, square_robj.shader)

    # Render a triangle with interpolated colors in the foreground
    # (push after background)
    # vertices with (position, color)
    vertices = Float32[
        -0.5, -0.5, 0.0, 0.2, 0.3, 0.8, 1.0,
         0.5, -0.5, 0.0, 0.8, 0.0, 0.2, 1.0,
         0.0,  0.5, 0.0, 0.8, 0.8, 0.0, 1.0
    ]
    layout = Hazel.BufferLayout(position = Point3f0, color = Point4f0)
    vertex_buffer = Hazel.VertexBuffer(vertices, layout)
    index_buffer = Hazel.IndexBuffer(UInt32[0, 1, 2])


    vertex_source = """
    #version 330 core

    layout(location = 0) in vec3 a_position; // a = attributed
    layout(location = 1) in vec4 a_color; // a = attributed

    uniform mat4 u_projection_view;
    uniform mat4 u_transform;

    out vec3 v_position; // v = varying
    out vec4 v_color; // v = varying

    void main(){
        v_position = a_position;
        v_color = a_color;
        gl_Position = u_projection_view * u_transform * vec4(a_position, 1.0);
    }
    """
    fragment_source = """
    #version 330 core

    layout(location = 0) out vec4 color; // a = attributed
    in vec3 v_position;
    in vec4 v_color;

    void main(){
        //color = vec4(0.8, 0.2, 0.3, 1.0);
        color = v_color;
    }
    """

    # push!(scene, Hazel.RenderObject(
    #     Hazel.Shader(vertex_source, fragment_source),
    #     Hazel.VertexArray(vertex_buffer, index_buffer)
    # ))
    triangle_robj = Hazel.RenderObject(
        Hazel.Shader("TriangleShader", vertex_source, fragment_source),
        Hazel.VertexArray(vertex_buffer, index_buffer)
    )
    push!(shader_library, triangle_robj.shader)


    # texture shader

    # tex_shader = Hazel.Shader(vertex_source, fragment_source)
    # tex_shader = Hazel.Shader(joinpath(Hazel.assetpath, "shaders", "Texture.glsl"))
    Hazel.load!(
        shader_library, joinpath(Hazel.assetpath, "shaders", "Texture.glsl")
    )
    tex_shader = shader_library["Texture"]
    texture_robj = Hazel.RenderObject(tex_shader, square_robj.vertex_array)

    texture = Hazel.Texture2D(joinpath(Hazel.assetpath, "textures", "Checkerboard.png"))
    alpha_texture = Hazel.Texture2D(joinpath(Hazel.assetpath, "textures", "swirl.png"))
    Hazel.bind(texture)
    Hazel.upload!(tex_shader, u_texture = Int32(0))

    sq_color = Float32[0.2, 0.4, 0.8]
    @eval function Hazel.render(l::ImGuiLayer)
        Hazel.CImGui.ColorEdit3("Square color", $sq_color)
    end

    ExampleLayer(
        Ref{Hazel.BasicApplication}(),
        name, Hazel.Renderer(), Hazel.Scene(camera, square_robj, triangle_robj),
        shader_library,
        square_robj, triangle_robj,
        texture_robj, texture, alpha_texture,
        camera, 1f0, 1f0,
        Float32[0, 0, 0], 0.1f0,
        sq_color
    )
end

function Hazel.attach(l::ExampleLayer, app::Hazel.AbstractApplication)
    @info "Attaching $(typeof(app))"
    l.app[] = app
end

function Hazel.update!(l::ExampleLayer, dt)
    app = l.app[]

    # Move camera
    offset = -Vec3f0(
        Hazel.keypressed(app, Hazel.KEY_RIGHT) * l.cam_translation_speed -
            Hazel.keypressed(app, Hazel.KEY_LEFT) * l.cam_translation_speed,
        Hazel.keypressed(app, Hazel.KEY_UP) * l.cam_translation_speed -
            Hazel.keypressed(app, Hazel.KEY_DOWN) * l.cam_translation_speed,
        0
    )
    Hazel.moveby!(l.camera, dt * offset)
    # Rotate camera
    rotation =
        Hazel.keypressed(app, Hazel.KEY_D) * l.cam_rotation_speed -
        Hazel.keypressed(app, Hazel.KEY_A) * l.cam_rotation_speed
    Hazel.rotateby!(l.camera, dt * rotation)

    # Move square
    offset = Vec3f0(
        Hazel.keypressed(app, Hazel.KEY_L) * l.square_translation_speed -
            Hazel.keypressed(app, Hazel.KEY_J) * l.square_translation_speed,
        Hazel.keypressed(app, Hazel.KEY_I) * l.square_translation_speed -
            Hazel.keypressed(app, Hazel.KEY_K) * l.square_translation_speed,
        0
    )
    l.square_position .+= offset
    scale = Hazel.scalematrix(Vec3f0(0.1))

    cblue = Hazel.Vec4f0(0.2, 0.3, 0.8, 1.0)
    cred = Hazel.Vec4f0(0.8, 0.2, 0.3, 1.0)

    # material = Hazel.Material(flat_color_shader)
    # mi = MaterialInstance(material)
    # color!(mi, u_color = cred)
    # apply!(square_mesh, mi)

    Hazel.clear(Hazel.RenderCommand)
    # Hazel.submit(l.renderer, l.scene)
    Hazel.bind(l.square_robj)
    Hazel.upload!(l.square_robj.shader, u_color = Vec3f0(l.square_color))

    for x in -10:10
        for y in -10:10
            pos = Vec3f0(l.square_position) + Vec3f0(0.11f0*x, 0.11f0*y, 0f0)
            transform = Hazel.translationmatrix(pos) * scale
            Hazel.submit(
                l.renderer, l.square_robj, Hazel.projection_view(l.camera),
                transform
            )
        end
    end

    Hazel.bind(l.texture)
    transform = Hazel.scalematrix(Vec3f0(1.5))
    Hazel.submit(l.renderer, l.texture_robj, Hazel.projection_view(l.camera), transform)
    Hazel.unbind(l.texture_robj)
    Hazel.bind(l.alpha_texture)
    Hazel.submit(l.renderer, l.texture_robj, Hazel.projection_view(l.camera), transform)

    nothing
end


Hazel.destroy(l::ExampleLayer) = Hazel.destroy(l.scene)
Hazel.string(l::ExampleLayer) = l.name


app = Hazel.BasicApplication()
push!(app, ExampleLayer())
task = run(app)
