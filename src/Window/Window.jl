# No point in this if it's not mutable
mutable struct WindowProperties
    title::String
    width::UInt32
    height::UInt32

    function WindowProperties(
            title = "Hazel Engine",
            width = 1280,
            height = 720
        )
        new(title, width, height)
    end
end


"""
    AbstractWindow

Any Widow inheriting from AbstractWindow should implement

- A constructor `Window(title, width, height[, vsync])`
- A destructor `destroy!(window)`
- `update!`
- `set_event_callback`
- `set_vsync(window, bool)`
- `get_vsync(window)`

"""
abstract type AbstractWindow end



# This kinda has to be mutable right? :(
struct GLFWWindow <: AbstractWindow
    window::GLFW.Window
    window_properties::WindowProperties
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
            if action == GLFW.PRESS         ec(KeyPressedEvent{key}(0))
            elseif action == GLFW.REPEAT    ec(KeyPressedEvent{key}(1))
            elseif action == GLFW.RELEASE   ec(KeyReleasedEvent{key}())
            end
        end)
        GLFW.SetMouseButtonCallback(glfw_w, (_, button, action, mods) -> begin
            if action == GLFW.PRESS         ec(MouseButtonPressedEvent{button}())
            elseif action == GLFW.RELEASE   ec(MouseButtonReleasedEvent{button}())
            end
        end)
        GLFW.SetScrollCallback(glfw_w, (_, dx, dy) -> ec(MouseScrolledEvent(dx, dy)))
        GLFW.SetCursorPosCallback(glfw_w, (_, x, y) -> ec(MouseMovedEvent(x, y)))
        GLFW.SetErrorCallback((_error, description) -> @error "GLFW Error $_error\n$description")
    end

    window
end

destroy(window::GLFWWindow) = GLFW.DestroyWindow(window.window)
set_vsync(window::GLFWWindow, on::Bool) = GLFW.SwapInterval(on ? 1 : 0)


function update!(window::GLFWWindow)
    GLFW.PollEvents()
    GLFW.SwapBuffers(window.window)
    nothing
end
