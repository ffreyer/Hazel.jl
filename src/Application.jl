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
        new(GLFWWindow(WindowProperties()), true)
    end
end

function Base.run(app::DummyApplication)
    while app.running
        on_update(app.window)
        yield()
    end
end

function destroy(app::DummyApplication)
    app.running = false
    destroy(window)
    nothing
end
