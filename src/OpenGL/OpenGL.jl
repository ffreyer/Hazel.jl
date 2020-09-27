import Base: bind

abstract type AbstractGPUObject end
abstract type BufferLayout end
abstract type AbstractGPUBuffer <: AbstractGPUObject end
abstract type AbstractVertexBuffer <: AbstractGPUBuffer end
abstract type AbstractIndexBuffer <: AbstractGPUBuffer end
abstract type AbstractShader <: AbstractGPUObject end
abstract type AbstractVertexArray <: AbstractGPUObject end
abstract type AbstractRenderCommand end
abstract type AbstractTexture <: AbstractGPUObject end



"""
    bind(gpu_object)

Binds the given `gpu_object`.
"""
Base.bind

"""
    unbind(gpu_onject)

Unbinds the given ´gpu_object`.
"""
unbind

"""
    destroy(gpu_onject)

Cleans up the given `gpu_object`.
"""
destroy

"""
    id(gpu_object)

Returns the renderer id of a given `gpu_object`.
"""
id(o::AbstractGPUObject) = o.id


# type conversions
include("gl_utils.jl")

# Layouting for VertexBuffer
include("BufferLayout.jl")
# Vertex and Index Buffer
include("Buffer.jl")
# Shader w/ uniform upload! methods
include("Shader.jl")
include("VertexArray.jl")
# Layer of abstraction between Renderer and backend
include("RenderCommand.jl")
include("Texture.jl")
include("FrameBuffer.jl")