include("Inputs.jl")


mutable struct DummyApplication <: AbstractApplication
    window::Window
    running::Bool
    # allow MutableLayerStack -> StaticLayerStack
    layerstack::AbstractLayerStack

    vertex_array::VertexArray
    shader::Shader

    sq_vertex_array::VertexArray
    sq_shader::Shader

    function DummyApplication()
        @info "Application starting up"
        app = new()
        init!(app)
        push_overlay!(app, ImGuiLayer())

        @info (glGetString(GL_VENDOR) |> unsafe_string)
        @info (glGetString(GL_RENDERER) |> unsafe_string)
        @info (glGetString(GL_VERSION) |> unsafe_string)

        app
    end
end


function init!(app::DummyApplication)
    if !isdefined(app, :window) || !isopen(app.window)
        app.window = Window(e -> handle!(app, e))
    end

    app.running = true

    if !isdefined(app, :layerstack)
        app.layerstack = MutableLayerStack()
    end

    # NOTE
    # If we make VertexArray take a VertexBuffer and IndexBuffer on
    # creation we kinda need to unbind first.
    # Otherwise:
    # create first vertex array [OK]
    # create new vertex buffer [OVERWRITES previous vertex array if still bound]



    vertices = Float32[
        -0.5, -0.5, 0.0, 0.2, 0.3, 0.8, 1.0,
         0.5, -0.5, 0.0, 0.8, 0.0, 0.2, 1.0,
         0.0,  0.5, 0.0, 0.8, 0.8, 0.0, 1.0
    ]
    layout = BufferLayout(position = Point3f0, color = Point4f0)
    vertex_buffer = VertexBuffer(vertices, layout)
    index_buffer = IndexBuffer(UInt32[0, 1, 2])
    app.vertex_array = VertexArray(vertex_buffer, index_buffer)


    # maybe unbind
    vertices = Float32[
        -0.75, -0.75, 0.0,
         0.75, -0.75, 0.0,
        -0.75,  0.75, 0.0,
         0.75,  0.75, 0.0
    ]
    layout = BufferLayout(position = Point3f0)
    sq_vertex_buffer = VertexBuffer(vertices, layout)
    sq_index_buffer = IndexBuffer(UInt32[0, 1, 2, 1, 2, 3])
    app.sq_vertex_array = VertexArray(sq_vertex_buffer, sq_index_buffer)


    vertex_source = """
    #version 330 core

    layout(location = 0) in vec3 a_position; // a = attributed
    layout(location = 1) in vec4 a_color; // a = attributed

    out vec3 v_position; // v = varying
    out vec4 v_color; // v = varying

    void main(){
        v_position = a_position;
        v_color = a_color;
        gl_Position = vec4(a_position, 1.0);
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

    app.shader = Shader(vertex_source, fragment_source)



    vertex_source2 = """
    #version 330 core

    layout(location = 0) in vec3 a_position; // a = attributed

    out vec3 v_position; // v = varying

    void main(){
        v_position = a_position;
        gl_Position = vec4(a_position, 1.0);
    }
    """
    fragment_source2 = """
    #version 330 core

    layout(location = 0) out vec4 color; // a = attributed
    in vec3 v_position;

    void main(){
        color = vec4(0.2, 0.3, 0.8, 1.0);
    }
    """

    app.sq_shader = Shader(vertex_source2, fragment_source2)


    app
end



function renderloop(app::AbstractApplication)
    renderer = Renderer()
    while app.running
        clear(RenderCommand)


        bind(app.sq_shader)
        draw_indexed(renderer, app.sq_vertex_array)
        bind(app.shader)
        draw_indexed(renderer, app.vertex_array)


        # Render layers in order (bottom to top)
        for layer in app.layerstack
            update!(layer)
        end

        update!(app.window)

        yield()
    end
    yield()
    empty!(app.layerstack, app)
    # If we dont call GLFW.DestroyWindow after the loop we get a segfault :(
    destroy(window(app))
end

function Base.run(app::AbstractApplication)
    init!(app)
    @async renderloop(app)
end

function destroy(app::AbstractApplication)
    app.running = false
    nothing
end

function handle!(app::AbstractApplication, event::AbstractEvent)
    # handle! returns true if the event has been processed
    handle!(window(app), event) && return true

    for layer in Iterators.reverse(app.layerstack)
        handle!(layer, event) && return true
    end

    @debug "Event $event has not been handled!"

    false
end


function Base.push!(app::AbstractApplication, layer::AbstractLayer)
    push!(app.layerstack, layer)
    attach(layer, app)
end
function push_overlay!(app::AbstractApplication, layer::AbstractLayer)
    push_overlay!(app.layerstack, layer)
    attach(layer, app)
end
function Base.pop!(app::AbstractApplication, layer::AbstractLayer)
    pop!(app.layerstack, layer)
    detach(layer, app)
end
function pop_overlay!(app::AbstractApplication, layer::AbstractLayer)
    pop_overlay!(app.layerstack, layer)
    detach(layer, app)
end

window(app::AbstractApplication) = app.window



function handle!(app::AbstractApplication, event::WindowCloseEvent)
    @warn "Closing Window"
    destroy(app)
    true
end
