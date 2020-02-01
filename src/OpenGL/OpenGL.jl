# type conversions
include("gl_utils.jl")

# GLFW Window construction + some event callbacks/handling
include("GLFW/GraphicsContext.jl")
include("GLFW/Window.jl")
include("GLFW/Inputs.jl")

# See Renderer/Renderer.jl
include("Buffer.jl")
include("Shader.jl")
include("VertexArray.jl")
