

include("Inputs.jl")


mutable struct DummyApplication <: AbstractApplication
    window::GLFWWindow
    running::Bool
    # allow MutableLayerStack -> StaticLayerStack
    layerstack::AbstractLayerStack

    vertex_array::Ref{UInt32}
    vertex_buffer::Ref{UInt32}
    index_buffer::Ref{UInt32}
    shader::Shader

    function DummyApplication()
        @warn "Julia Debugging"
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
        app.window = GLFWWindow(WindowProperties(), e -> handle!(app, e))
    end

    app.running = true

    if !isdefined(app, :layerstack)
        app.layerstack = MutableLayerStack()
    end


    # To be abstracted away later
    app.vertex_array = Ref{UInt32}()
    glGenVertexArrays(1, app.vertex_array)
    glBindVertexArray(app.vertex_array[])

    app.vertex_buffer = Ref{UInt32}()
    glGenBuffers(1, app.vertex_buffer)
    glBindBuffer(GL_ARRAY_BUFFER, app.vertex_buffer[])

    vertices = Float32[
        -0.5, -0.5, 0.0,
         0.5, -0.5, 0.0,
         0.0,  0.5, 0.0
    ]
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW)
    glEnableVertexAttribArray(0)
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3sizeof(Float32), C_NULL)

    app.index_buffer = Ref{UInt32}()
    glGenBuffers(1, app.index_buffer)
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, app.index_buffer[])

    indices = UInt32[0, 1, 2]
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW)

    vertex_source = """
    #version 330 core

    layout(location = 0) in vec3 a_position; // a = attributed
    out vec3 v_position; // v = varying

    void main(){
        v_position = a_position;
        gl_Position = vec4(a_position, 1.0);
    }
    """
    fragment_source = """
    #version 330 core

    layout(location = 0) out vec4 color; // a = attributed
    in vec3 v_position;

    void main(){
        //color = vec4(0.8, 0.2, 0.3, 1.0);
        color = vec4(0.7 * v_position + 0.5, 1.0);
    }
    """

    app.shader = Shader(vertex_source, fragment_source)

    app
end



function renderloop(app::AbstractApplication)
    while app.running
        ModernGL.glClearColor(0.1, 0.1, 0.1, 1)
        ModernGL.glClear(ModernGL.GL_COLOR_BUFFER_BIT)

        # doesn't draw yet
        bind(app.shader)
        glBindVertexArray(app.vertex_array[])
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, app.index_buffer[])
        glDrawElements(GL_TRIANGLES, 3, GL_UNSIGNED_INT, C_NULL)


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
