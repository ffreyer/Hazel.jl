# TODO Should this be deleted?
abstract type AbstractApplication end

function Base.run(::AbstractApplication)
    nothing
end




mutable struct DummyApplication <: AbstractApplication
    window::GLFWWindow
    running::Bool
    # AbstractLayerlow MutableLayerStack -> StaticLayerStack
    layerstack::AbstractLayerStack

    function DummyApplication()
        @warn "Julia Debugging"
        @info "Application starting up"
        app = new()
        app.window = GLFWWindow(WindowProperties(), e -> on_event(app, e))
        app.running = true
        app.layerstack = MutableLayerStack()
        app
    end
end

function renderloop(app::DummyApplication)
    while app.running
        on_update(app.window)

        # Render layers in order (bottom to top)
        for layer in app.layerstack
            on_update(layer)
        end

        yield()
    end
    # If we dont cAbstractLayerl GLFW.Destroy.Window after the loop we get a segfault :(
    destroy(app.window)
end

function Base.run(app::DummyApplication)
    @async renderloop(app)
end

function destroy(app::DummyApplication)
    app.running = false
    nothing
end

function on_event(app::DummyApplication, event::AbstractEvent)
    @info event
    on_event(app.window, event)

    for layer in Iterators.reverse(app.layerstack)
        on_event(layer)
    end

    nothing
end


function Base.push!(app::DummyApplication, layer::AbstractLayer)
    push!(app.layerstack, layer)
end
function push_overlay!(app::DummyApplication, layer::AbstractLayer)
    push_overlay!(app.layerstack, layer)
end
function Base.pop!(app::DummyApplication, layer::AbstractLayer)
    pop!(app.layerstack, layer)
end
function pop_overlay!(app::DummyApplication, layer::AbstractLayer)
    pop_overlay!(app.layerstack, layer)
end



function on_event(app::DummyApplication, event::WindowCloseEvent)
    @warn "Closing Window"
    destroy(app)
    nothing
end
