include("Inputs.jl")


mutable struct BasicApplication <: AbstractApplication
    window::Window
    running::Bool
    # allow MutableLayerStack -> StaticLayerStack
    layerstack::AbstractLayerStack
end
function BasicApplication()
    @info "Application starting up"

    app = BasicApplication(
        Window(e -> handle!(app, e)),
        true,
        MutableLayerStack()
    )

    init!(app)

    @info (glGetString(GL_VENDOR) |> unsafe_string)
    @info (glGetString(GL_RENDERER) |> unsafe_string)
    @info (glGetString(GL_VERSION) |> unsafe_string)

    app
end


function init!(app::BasicApplication)
    if !isdefined(app, :window) || !isopen(app.window)
        app.window = Window(e -> handle!(app, e))
    end

    app.running = true
    push_overlay!(app, ImGuiLayer())

    app
end



function renderloop(app::AbstractApplication)
    renderer = Renderer()
    t = time()
    while app.running
        new_t = time()
        dt = new_t - t
        t = new_t

        # Render layers in order (bottom to top)
        for layer in app.layerstack
            update!(layer, dt)
        end

        update!(app.window, dt)

        yield()
    end
    yield()
    destroy.(app.layerstack)
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
