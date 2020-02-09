################################################################################
### General Interface functions
################################################################################


abstract type AbstractGraphicsContext end
abstract type AbstractGPUObject end
abstract type AbstractRenderCommand end

"""
    bind(gpu_object)

Binds the given `gpu_object`.
"""
@backend bind

"""
    unbind(gpu_onject)

Unbinds the given ´gpu_object`.
"""
@backend unbind

"""
    destroy(gpu_onject)

Cleans up the given `gpu_object`.
"""
@backend destroy(::AbstractGPUObject)


################################################################################
### Includes
################################################################################


# You can't create a type `T` if you define `T()` beforehand
# So some of these files are kinda sorry


include("GraphicsContext.jl")

# VertexBuffer, IndexBuffer Interface & docs
# BufferLayout
include("Buffer.jl")

# Shader Interface & docs
include("Shader.jl")

# VertexArray Interface & docs
include("VertexArray.jl")

# "high"-level Renderer implementation
include("Renderer.jl")
