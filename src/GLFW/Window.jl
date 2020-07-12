struct Window <: AbstractWindow
    context::GLFWContext
    properties::WindowProperties
end


"""
    Window(properties::WindowProperties, event_callback::Function[, vsync = true])
    Window(event_callback::Function[, vsync = true, name = "Hazel Engine", widht=1280, height=720])

Creates a new Window with the give `properties` and event callback function
`event_callback`.

# Warning

There is explicit cleanup required! Call destroy(window)´ to destroy the window.
"""
function Window(
        event_callback::Function;
        vsync=true, name="Hazel Window", width=1280, height=720
    )
    Window(WindowProperties(name, width, height, true), event_callback, vsync=vsync)
end
@HZ_profile function Window(props::WindowProperties, event_callback::Function; vsync=true)
    @info "Creating window $(props.title) ($(props.width), $(props.height))"

    @HZ_profile "GLFW.CreateWindow" glfw_window = GLFW.CreateWindow(props.width, props.height, props.title)
    context = GLFWContext(glfw_window)
    init(context) # GLFW.MakeContextCurrent(glfw_window)
    window = Window(context, props)
    vsync ? enable_vsync(window) : disable_vsync(window)

    # Callbacks
    let
        glfw_w = glfw_window
        ec = event_callback
        GLFW.SetWindowSizeCallback(glfw_w, (_, w, h) -> ec(WindowResizeEvent(w, h)))
        GLFW.SetWindowCloseCallback(glfw_w, _ -> ec(WindowCloseEvent()))
        GLFW.SetWindowIconifyCallback(glfw_w, (_, iconified) -> if iconified
            ec(WindowMinimizedEvent())
        else
            ec(WindowRestoredEvent())
        end)
        GLFW.SetWindowFocusCallback(glfw_w, (_, focused) -> if focused
            ec(WindowFocusEvent())
        else
            ec(WindowLostFocusEvent())
        end)
        GLFW.SetKeyCallback(glfw_w, (_, key, scancode, action, mods) -> begin
            if action == GLFW.PRESS
                ec(KeyPressedEvent{Key(key)}(0, scancode, mods))
            elseif action == GLFW.REPEAT
                ec(KeyPressedEvent{Key(key)}(1, scancode, mods))
            elseif action == GLFW.RELEASE
                ec(KeyReleasedEvent{Key(key)}(scancode, mods))
            end
        end)
        GLFW.SetMouseButtonCallback(glfw_w, (_, button, action, mods) -> begin
            if action == GLFW.PRESS
                ec(MouseButtonPressedEvent{MouseButton(button)}(mods))
            elseif action == GLFW.RELEASE
                ec(MouseButtonReleasedEvent{MouseButton(button)}(mods))
            end
        end)
        GLFW.SetScrollCallback(glfw_w, (_, dx, dy) -> ec(MouseScrolledEvent(dx, dy)))
        GLFW.SetCursorPosCallback(glfw_w, (_, x, y) -> ec(MouseMovedEvent(x, y)))
        GLFW.SetErrorCallback((_error, description) -> @error "GLFW Error $_error\n$description")
    end

    window
end

@HZ_profile function destroy(window::Window)
    window.properties.isopen = false
    GLFW.DestroyWindow(native_window(window))
    nothing
end
isopen(window::Window) = window.properties.isopen
enable_vsync(window::Window) = GLFW.SwapInterval(1)
disable_vsync(window::Window) = GLFW.SwapInterval(0)


@HZ_profile function update!(window::Window, dt)
    GLFW.PollEvents()
    swap_buffers(window.context)
    nothing
end

@inline native_window(window::Window) = native_window(window.context)

aspect_ratio(w::Window) = aspect_ratio(w.properties)
