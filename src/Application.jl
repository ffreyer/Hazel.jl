abstract type AbstractApplication end




mutable struct DummyApplication <: AbstractApplication
    window::GLFWWindow
    running::Bool
    # AbstractLayerlow MutableLayerStack -> StaticLayerStack
    layerstack::AbstractLayerStack

    function DummyApplication()
        @warn "Julia Debugging"
        @info "Application starting up"
        app = new()
        app.window = GLFWWindow(WindowProperties(), e -> handle!(app, e))
        app.running = true
        app.layerstack = MutableLayerStack()
        app
    end
end

function renderloop(app::AbstractApplication)
    while app.running
        update!(app.window)

        # Render layers in order (bottom to top)
        for layer in app.layerstack
            update!(layer)
        end

        yield()
    end
    # If we dont cAbstractLayerl GLFW.Destroy.Window after the loop we get a segfault :(
    destroy(app.window)
end

function Base.run(app::AbstractApplication)
    @async renderloop(app)
end

function destroy(app::AbstractApplication)
    app.running = false
    nothing
end

function handle!(app::AbstractApplication, event::AbstractEvent)
    # handle! returns true if the event has been processed
    handle!(app.window, event) && return true

    for layer in Iterators.reverse(app.layerstack)
        handle!(layer, event) && return true
    end

    @warn "Event $event has not been handled!"

    false
end


function Base.push!(app::AbstractApplication, layer::AbstractLayer)
    push!(app.layerstack, layer)
end
function push_overlay!(app::AbstractApplication, layer::AbstractLayer)
    push_overlay!(app.layerstack, layer)
end
function Base.pop!(app::AbstractApplication, layer::AbstractLayer)
    pop!(app.layerstack, layer)
end
function pop_overlay!(app::AbstractApplication, layer::AbstractLayer)
    pop_overlay!(app.layerstack, layer)
end



function handle!(app::AbstractApplication, event::WindowCloseEvent)
    @warn "Closing Window"
    destroy(app)
    true
end
