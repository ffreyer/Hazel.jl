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

    camera::Hazel.OrthographicCamera
    cam_translation_speed::Float32
    cam_rotation_speed::Float32
end

function ExampleLayer(name::String = "Example")
    # Build a basic Scene
    camera = Hazel.OrthographicCamera(-1.6f0, 1.6f0, -0.9f0, 0.9f0)
    scene = Hazel.Scene(camera)


    # Render a Rectangle in the background (push first)
    # positions
    vertices = Float32[
        -0.75, -0.75, 0.0,
         0.75, -0.75, 0.0,
        -0.75,  0.75, 0.0,
         0.75,  0.75, 0.0
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

    out vec3 v_position; // v = varying

    void main(){
        v_position = a_position;
        gl_Position = u_projection_view * vec4(a_position, 1.0);
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

    # Combine everything into a renderobject. A Renderobject has all the
    # information necessary to be rendered.
    # Add it to the Scene which is renderer on this layer
    push!(scene, Hazel.RenderObject(
        Hazel.Shader(vertex_source, fragment_source),
        Hazel.VertexArray(vertex_buffer, index_buffer)
    ))


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

    out vec3 v_position; // v = varying
    out vec4 v_color; // v = varying

    void main(){
        v_position = a_position;
        v_color = a_color;
        gl_Position = u_projection_view * vec4(a_position, 1.0);
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

    push!(scene, Hazel.RenderObject(
        Hazel.Shader(vertex_source, fragment_source),
        Hazel.VertexArray(vertex_buffer, index_buffer)
    ))

    ExampleLayer(
        Ref{Hazel.BasicApplication}(),
        name, Hazel.Renderer(), scene,
        camera, 0.01f0, 0.05f0
    )
end

function Hazel.attach(l::ExampleLayer, app::Hazel.AbstractApplication)
    @info "Attaching $(typeof(app))"
    l.app[] = app
end

function Hazel.update!(l::ExampleLayer)
    app = l.app[]

    offset = Vec3f0(
        Hazel.keypressed(app, Hazel.KEY_RIGHT) * l.cam_translation_speed -
            Hazel.keypressed(app, Hazel.KEY_LEFT) * l.cam_translation_speed,
        Hazel.keypressed(app, Hazel.KEY_UP) * l.cam_translation_speed -
            Hazel.keypressed(app, Hazel.KEY_DOWN) * l.cam_translation_speed,
        0
    )
    Hazel.moveby!(l.camera, offset)
    rotation =
        Hazel.keypressed(app, Hazel.KEY_D) * l.cam_rotation_speed -
        Hazel.keypressed(app, Hazel.KEY_A) * l.cam_rotation_speed
    Hazel.rotateby!(l.camera, rotation)

    Hazel.clear(Hazel.RenderCommand)
    Hazel.submit(l.renderer, l.scene)
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
run(app)
