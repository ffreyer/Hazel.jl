# No point in this if it's not mutable
mutable struct WindowProperties
    title::String
    width::UInt32
    height::UInt32
    isopen::Bool

    function WindowProperties(
            title = "Hazel Engine",
            width = 1280,
            height = 720,
            isopen = true
        )
        new(title, width, height, isopen)
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



include("GLFW/Window.jl")
include("GLFW/Inputs.jl")
