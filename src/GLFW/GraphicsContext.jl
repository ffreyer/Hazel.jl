abstract type GraphicsContext end
struct GLFWContext <: GraphicsContext
    native_window::GLFW.Window
end

"""
    GraphicsContext(native_window)

Creates a `GraphicsContext` which handles interactions with the window api.
"""
GraphicsContext(native_window::GLFW.Window) =GLFWContext(native_window)
"""
    init(graphics_context)

Initializes the given `graphics_context`.
"""
init(context::GLFWContext) = GLFW.MakeContextCurrent(context.native_window)
"""
    swap_buffers(graphics_context)

Swaps the buffers of the given `graphics_context`
"""
swap_buffers(context::GLFWContext) = GLFW.SwapBuffers(context.native_window)
"""
    native_window(graphics_context)

Returns the native window of the given `graphics_context`
"""
native_window(context::GLFWContext) = context.native_window
