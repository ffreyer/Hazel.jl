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

    square_robj::Hazel.RenderObject
    triangle_robj::Hazel.RenderObject

    camera::Hazel.OrthographicCamera
    cam_translation_speed::Float32
    cam_rotation_speed::Float32

    square_position::Vector{Float32} # mutable struct w/ Vec3f0 might be better
    square_translation_speed::Float32
end

function ExampleLayer(name::String = "Example")
    # Build a basic Scene
    camera = Hazel.OrthographicCamera(-1.6f0, 1.6f0, -0.9f0, 0.9f0)
    scene = Hazel.Scene(camera)


    # Render a Rectangle in the background (push first)
    # positions
    vertices = Float32[
        -0.5, -0.5, 0.0,
         0.5, -0.5, 0.0,
        -0.5,  0.5, 0.0,
         0.5,  0.5, 0.0
    ]
    # vertices contains "positions" of type "Point3f0"
    # (Float32 3 component vectors)
    layout = Hazel.BufferLayout(position = Point3f0)
    # vertices + layout are bundled
    vertex_buffer = Hazel.VertexBuffer(vertices, layout)
    # indices to connect vertices (draw two triangles to make rectangle)
    index_buffer = Hazel.IndexBuffer(UInt32[0, 1, 2, 1, 2, 3])

    # Basic shader that takes positions and a matrix to draw
    # a constant color object
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
    in vec3 v_position;

    void main(){
        color = vec4(0.2, 0.3, 0.8, 1.0);
    }
    """

    # # Combine everything into a renderobject. A Renderobject has all the
    # # information necessary to be rendered.
    # # Add it to the Scene which is renderer on this layer
    # push!(scene, Hazel.RenderObject(
    #     Hazel.Shader(vertex_source, fragment_source),
    #     Hazel.VertexArray(vertex_buffer, index_buffer)
    # ))
    square_robj = Hazel.RenderObject(
        Hazel.Shader(vertex_source, fragment_source),
        Hazel.VertexArray(vertex_buffer, index_buffer)
    )

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
        Hazel.Shader(vertex_source, fragment_source),
        Hazel.VertexArray(vertex_buffer, index_buffer)
    )

    ExampleLayer(
        Ref{Hazel.BasicApplication}(),
        name, Hazel.Renderer(), Hazel.Scene(camera, square_robj, triangle_robj),
        square_robj, triangle_robj,
        camera, 1f0, 1f0,
        Float32[0, 0, 0], 0.1f0
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

    Hazel.clear(Hazel.RenderCommand)
    # Hazel.submit(l.renderer, l.scene)
    for x in -10:10
        for y in -10:10
            pos = Vec3f0(l.square_position) + Vec3f0(0.11f0*x, 0.11f0*y, 0f0)
            transform = Hazel.translationmatrix(pos) * scale
            Hazel.submit(l.renderer, l.square_robj, Hazel.projection_view(l.camera), transform)
        end
    end
    Hazel.submit(l.renderer, l.triangle_robj, Hazel.projection_view(l.camera))
    nothing
end


# function Hazel.handle!(l::ExampleLayer, e::Hazel.KeyboardEvent{Hazel.KEY_LEFT})
#     l.cam_pos[1] += l.cam_speed
#     true
# end
# function Hazel.handle!(l::ExampleLayer, e::Hazel.KeyboardEvent{Hazel.KEY_RIGHT})
#     l.cam_pos[1] -= l.cam_speed
#     true
# end
# function Hazel.handle!(l::ExampleLayer, e::Hazel.KeyboardEvent{Hazel.KEY_DOWN})
#     l.cam_pos[2] += l.cam_speed
#     true
# end
# function Hazel.handle!(l::ExampleLayer, e::Hazel.KeyboardEvent{Hazel.KEY_UP})
#     l.cam_pos[2] -= l.cam_speed
#     true
# end
Hazel.destroy(l::ExampleLayer) = Hazel.destroy(l.scene)
Hazel.string(l::ExampleLayer) = l.name


app = Hazel.BasicApplication()
push!(app, ExampleLayer())
task = run(app)
