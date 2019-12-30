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
- `on_update`
- `set_event_callback`
- `set_vsync(window, bool)`
- `get_vsync(window)`

"""
abstract type AbstractWindow end


# To be passed to GLFW
# struct WindowData
#     title::String
#     width::UInt32
#     height::UInt32
#     vsync::Bool
# end
# function WindowData(p::WindowProperties, vsync=true)
#     WindowData(p.title, p.width, p.height, vsync)
# end

# This kinda has to be mutable right? :(
struct GLFWWindow <: AbstractWindow
    window::GLFW.Window
    window_properties::WindowProperties
end

function GLFWWindow(props::WindowProperties, vsync=true)
    # window_data = WindowData(props, vsync)
    @info "Creating window $(props.title) ($(props.width), $(props.height))"

    glfw_window = GLFW.CreateWindow(props.width, props.height, props.title)
    GLFW.MakeContextCurrent(glfw_window)
    window = GLFWWindow(glfw_window, props)
    set_vsync(window, vsync)
    window
end

destroy(window::GLFWWindow) = GLFW.DestroyWindow(window.window)
set_vsync(window::GLFWWindow, on::Bool) = GLFW.SwapInterval(on ? 1 : 0)
# get_vsync

function on_update(window::GLFWWindow)
    GLFW.PollEvents()
    GLFW.SwapBuffers(window.window)
    nothing
end
