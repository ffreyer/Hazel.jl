struct OpenGLContext <: GraphicsContext
    native_window::GLFW.Window
end

GraphicsContext(native_window::GLFW.Window) =OpenGLContext(native_window)
init(context::OpenGLContext) = GLFW.MakeContextCurrent(context.native_window)
swap_buffers(context::OpenGLContext) = GLFW.SwapBuffers(context.native_window)
native_window(context::OpenGLContext) = context.native_window
