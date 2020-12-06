include("Inputs.jl")


mutable struct BasicApplication <: AbstractApplication
    window::Window
    running::Bool
    minimized::Bool
    # allow MutableLayerStack -> StaticLayerStack
    layerstack::AbstractLayerStack
end
@HZ_profile function BasicApplication(name="Hazel")
    @info "Application starting up"

    app = BasicApplication(
        Window(e -> handle!(app, e), name=name),
        true, false,
        MutableLayerStack()
    )

    @info (glGetString(GL_VENDOR) |> unsafe_string)
    @info (glGetString(GL_RENDERER) |> unsafe_string)
    @info (glGetString(GL_VERSION) |> unsafe_string)
    @info (glGetString(GL_SHADING_LANGUAGE_VERSION) |> unsafe_string)

    app
end


@HZ_profile function init!(app::BasicApplication)
    if !isdefined(app, :window) || !isopen(app.window)
        app.window = Window(e -> handle!(app, e))
    end

    app.running = true
    push_overlay!(app, ImGuiLayer())

    app
end



function renderloop(app::AbstractApplication)
    try
        ts = Timestep()
        while app.running
            @HZ_profile "renderloop" begin
                ts = Timestep(ts)

                @HZ_profile "Full Layer update!" if !app.minimized
                    # Render layers in order (bottom to top)
                    @HZ_profile "Normal Layer update!" begin
                        for layer in app.layerstack
                            update!(app, layer, ts)
                        end
                    end

                    # NOTE
                    # This is a bit of a hack
                    # I'm assuming that all ImGui layers will be overlay layers
                    @HZ_profile "ImGui Layer update!" begin
                        for overlay in app.layerstack.overlayers
                            if overlay isa ImGuiLayer
                                Begin(overlay)
                                for layer in app.layerstack
                                    update!(app, overlay, layer, ts)
                                end
                                End(overlay)
                            end
                        end
                    end
                end

                # This also polls events
                update!(app.window)

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

    for layer in Iterators.reverse(app.layerstack)
        handle!(layer, event) && return true
    end

    @debug "Event $event has not been handled!"

    false
end

function handle!(app::AbstractApplication, ::WindowCloseEvent)
    @warn "Closing Window"
    destroy(app)
    true
end
function handle!(app::AbstractApplication, ::WindowRestoredEvent)
    restore!(app)
    true
end
function handle!(app::AbstractApplication, event::WindowResizeEvent)
    resize!(app, event.width, event.height)
    false
end
function handle!(app::AbstractApplication, ::WindowMinimizedEvent)
    minimize!(app)
    true
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


function minimize!(app::AbstractApplication)
    app.minimized = true
end
function restore!(app::AbstractApplication)
    app.minimized = false
end
const __max_screen_size = 16384
@HZ_profile function resize!(app::AbstractApplication, width::Integer, height::Integer)
    if (1 ≤ width ≤ __max_screen_size) && (1 ≤ height ≤ __max_screen_size)
        # Renderer.resize!(width, height)
        RenderCommand.viewport(0, 0, width, height)
    else
        @warn "Attempt to resize to ($width, $height) failed."
    end
    return nothing
end
