struct OpenGLContext <: AbstractGraphicsContext
    native_window::GLFW.Window
end

function init(context::OpenGLContext)
    GLFW.MakeContextCurrent(context.native_window)
end

function swap_buffers(context::OpenGLContext)
    GLFW.SwapBuffers(context.native_window)
end

native_window(context::OpenGLContext) = context.native_window
