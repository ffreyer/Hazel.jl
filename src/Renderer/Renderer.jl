abstract type AbstractGraphicsContext end
# implements
# init
# swap_buffers

# TODO In seperate file? (once we implenment a rendering interface)
abstract type RenderAPI end
abstract type OpenGL <: RenderAPI end

include("OpenGLContext.jl")
include("Buffer.jl")
include("Shader.jl")
include("VertexArray.jl")
