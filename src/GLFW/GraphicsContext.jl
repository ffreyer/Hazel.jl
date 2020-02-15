struct GLFWContext <: GraphicsContext
    native_window::GLFW.Window
end

GraphicsContext(native_window::GLFW.Window) =GLFWContext(native_window)
init(context::GLFWContext) = GLFW.MakeContextCurrent(context.native_window)
swap_buffers(context::GLFWContext) = GLFW.SwapBuffers(context.native_window)
native_window(context::GLFWContext) = context.native_window
