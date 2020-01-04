

include("Inputs.jl")


mutable struct DummyApplication <: AbstractApplication
    window::GLFWWindow
    running::Bool
    # allow MutableLayerStack -> StaticLayerStack
    layerstack::AbstractLayerStack

    function DummyApplication()
        @warn "Julia Debugging"
        @info "Application starting up"
        app = new()
        init!(app)
        push_overlay!(app, ImGuiLayer())
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

    app
end


function renderloop(app::AbstractApplication)
    while app.running
        ModernGL.glClearColor(1, 0, 1, 1)
        ModernGL.glClear(ModernGL.GL_COLOR_BUFFER_BIT)

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
