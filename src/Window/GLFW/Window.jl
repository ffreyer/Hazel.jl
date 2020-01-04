

# This kinda has to be mutable right? :(
struct GLFWWindow <: AbstractWindow
    window::GLFW.Window
    properties::WindowProperties
end

function GLFWWindow(props::WindowProperties, event_callback::Function, vsync=true)
    # window_data = WindowData(props, vsync)
    @info "Creating window $(props.title) ($(props.width), $(props.height))"

    glfw_window = GLFW.CreateWindow(props.width, props.height, props.title)
    GLFW.MakeContextCurrent(glfw_window)
    window = GLFWWindow(glfw_window, props)
    set_vsync(window, vsync)

    # Callbacks
    let
        glfw_w = glfw_window
        ec = event_callback
        GLFW.SetWindowSizeCallback(glfw_w, (_, w, h) -> ec(WindowResizeEvent(w, h)))
        GLFW.SetWindowCloseCallback(glfw_w, _ -> ec(WindowCloseEvent()))
        GLFW.SetKeyCallback(glfw_w, (_, key, scancode, action, mods) -> begin
            if action == GLFW.PRESS         ec(KeyPressedEvent{Key(Int64(key))}(0))
            elseif action == GLFW.REPEAT    ec(KeyPressedEvent{Key(Int64(key))}(1))
            elseif action == GLFW.RELEASE   ec(KeyReleasedEvent{Key(Int64(key))}())
            end
        end)
        GLFW.SetMouseButtonCallback(glfw_w, (_, button, action, mods) -> begin
            if action == GLFW.PRESS         ec(MouseButtonPressedEvent{MouseButton(Int64(key))}())
            elseif action == GLFW.RELEASE   ec(MouseButtonReleasedEvent{MouseButton(Int64(key))}())
            end
        end)
        GLFW.SetScrollCallback(glfw_w, (_, dx, dy) -> ec(MouseScrolledEvent(dx, dy)))
        GLFW.SetCursorPosCallback(glfw_w, (_, x, y) -> ec(MouseMovedEvent(x, y)))
        GLFW.SetErrorCallback((_error, description) -> @error "GLFW Error $_error\n$description")
    end

    window
end

function destroy(window::GLFWWindow)
    window.properties.isopen = false
    GLFW.DestroyWindow(window.window)
    nothing
end
isopen(window::GLFWWindow) = window.properties.isopen
set_vsync(window::GLFWWindow, on::Bool) = GLFW.SwapInterval(on ? 1 : 0)


function update!(window::GLFWWindow)
    GLFW.PollEvents()
    GLFW.SwapBuffers(window.window)
    nothing
end

native_window(window::GLFWWindow) = window.window
