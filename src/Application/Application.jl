include("Inputs.jl")


mutable struct BasicApplication <: AbstractApplication
    window::Window
    running::Bool
    minimized::Bool
    # allow MutableLayerStack -> StaticLayerStack
    layerstack::AbstractLayerStack
end
@HZ_profile function BasicApplication()
    @info "Application starting up"

    app = BasicApplication(
        Window(e -> handle!(app, e)),
        true, false,
        MutableLayerStack()
    )

    @info (glGetString(GL_VENDOR) |> unsafe_string)
    @info (glGetString(GL_RENDERER) |> unsafe_string)
    @info (glGetString(GL_VERSION) |> unsafe_string)

    app
end


@HZ_profile function init!(app::BasicApplication)
    if !isdefined(app, :window) || !isopen(app.window)
        app.window = Window(e -> handle!(app, e))
    end

    app.running = true
    Renderer.init!()
    push_overlay!(app, ImGuiLayer())

    app
end



function renderloop(app::AbstractApplication)
    try
        t = time()
        while app.running
            @HZ_profile "renderloop" begin
                new_t = time()
                dt = new_t - t
                t = new_t

                if !app.minimized
                    # Render layers in order (bottom to top)
                    for layer in app.layerstack
                        update!(layer, dt)
                    end
                end

                # This also polls events
                update!(app.window, dt)

                yield()
            end
        end
        yield()
    catch e
        ce = CapturedException(e, Base.catch_backtrace())
        @error "Error in renderloop!" exception=ce
        rethrow(e)
    finally
        destroy.(app.layerstack)
        empty!(app.layerstack, app)
        destroy(window(app))
    end
end

function Base.run(app::AbstractApplication)
    init!(app)
    @async renderloop(app)
end

function destroy(app::AbstractApplication)
    app.running = false
    nothing
end

@HZ_profile function handle!(app::AbstractApplication, event::AbstractEvent)
    # handle! returns true if the event has been processed
    handle!(window(app), event) && return true
    event isa WindowMinimizedEvent && minimize!(app)
    event isa WindowRestoredEvent && restore!(app)
    event isa WindowResizeEvent && resize!(app, event.width, event.height)

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

function minimize!(app::AbstractApplication)
    app.minimized = true
    false
end
function restore!(app::AbstractApplication)
    app.minimized = false
    false
end
@HZ_profile function resize!(app::AbstractApplication, width, height)
    Renderer.resize!(width, height)
    false
end
