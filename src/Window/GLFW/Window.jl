

# This kinda has to be mutable right? :(
struct GLFWWindow{Context <: AbstractGraphicsContext} <: AbstractWindow
    context::Context
    properties::WindowProperties
end

function GLFWWindow(props::WindowProperties, event_callback::Function, vsync=true)
    # window_data = WindowData(props, vsync)
    @info "Creating window $(props.title) ($(props.width), $(props.height))"

    glfw_window = GLFW.CreateWindow(props.width, props.height, props.title)
    context = OpenGLContext(glfw_window)
    init(context)
    # ^ GLFW.MakeContextCurrent(glfw_window)
    window = GLFWWindow(context, props)
    set_vsync(window, vsync)

    # Callbacks
    let
        glfw_w = glfw_window
        ec = event_callback
        GLFW.SetWindowSizeCallback(glfw_w, (_, w, h) -> ec(WindowResizeEvent(w, h)))
        GLFW.SetWindowCloseCallback(glfw_w, _ -> ec(WindowCloseEvent()))
        GLFW.SetKeyCallback(glfw_w, (_, key, scancode, action, mods) -> begin
            if action == GLFW.PRESS
                ec(KeyPressedEvent{key}(0, scancode, mods))
            elseif action == GLFW.REPEAT
                ec(KeyPressedEvent{key}(1, scancode, mods))
            elseif action == GLFW.RELEASE
                ec(KeyReleasedEvent{key}(scancode, mods))
            end
        end)
        GLFW.SetMouseButtonCallback(glfw_w, (_, button, action, mods) -> begin
            if action == GLFW.PRESS
                ec(MouseButtonPressedEvent{button}(mods))
            elseif action == GLFW.RELEASE
                ec(MouseButtonReleasedEvent{button}(mods))
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
    GLFW.DestroyWindow(native_window(window))
    nothing
end
isopen(window::GLFWWindow) = window.properties.isopen
set_vsync(window::GLFWWindow, on::Bool) = GLFW.SwapInterval(on ? 1 : 0)


function update!(window::GLFWWindow)
    GLFW.PollEvents()
    swap_buffers(window.context)
    nothing
end

@inline native_window(window::GLFWWindow) = native_window(window.context)
