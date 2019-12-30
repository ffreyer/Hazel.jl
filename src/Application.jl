abstract type AbstractApplication end

function Base.run(::AbstractApplication)
    nothing
end



mutable struct DummyApplication <: AbstractApplication
    window::GLFWWindow
    running::Bool

    function DummyApplication()
        @warn "Julia Debugging"
        @info "Application starting up"
        app = new()
        app.window = GLFWWindow(WindowProperties(), e -> on_event(app, e))
        app.running = true
        app
    end
end

function renderloop(app::DummyApplication)
    while app.running
        on_update(app.window)
        yield()
    end
    # If we dont call GLFW.Destroy.Window after the loop we get a segfault :(
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
    nothing
end

function on_event(app::DummyApplication, event::WindowCloseEvent)
    @warn "Closing Window"
    destroy(app)
    nothing
end
