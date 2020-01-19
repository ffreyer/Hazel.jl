# TODO unify with Shader?
# maybe AbstractGPUObject?
abstract type AbstractGPUBuffer end
abstract type VertexBuffer <: AbstractGPUBuffer end
abstract type IndexBuffer <: AbstractGPUBuffer end

function VertexBuffer(vertices, api::Type{<: RenderAPI})
    throw(ArgumentError("VertexBuffer not implemented for $api."))
end
function IndexBuffer(indices, api::Type{<: RenderAPI})
    throw(ArgumentError("IndexBuffer not implemented for $api."))
end
# bind(b::AbstractGPUBuffer)
# unbind(b::AbstractGPUBuffer)



################################################################################
### VertexBuffer
################################################################################



struct OpenGLVertexBuffer <: VertexBuffer
    # TODO can this be UInt32?
    # Needs to be reference in delete!
    # but can we remake that reference on the fly? Or use a Pointer
    id::Ref{UInt32}
end

function VertexBuffer(vertices, api::Type{OpenGL} = OpenGL)
    id = Ref{UInt32}()
    # No glCreateBuffer in ModernGL :(
    glGenBuffers(1, id)
    glBindBuffer(GL_ARRAY_BUFFER, id[])
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW)
    OpenGLVertexBuffer(id)
end
bind(buffer::OpenGLVertexBuffer) = glBindBuffer(GL_ARRAY_BUFFER, buffer.id[])
unbind(buffer::OpenGLVertexBuffer) = glBindBuffer(GL_ARRAY_BUFFER, 0)
delete!(buffer::OpenGLVertexBuffer) = glDeleteBuffers(1, buffer.id)



################################################################################
### IndexBuffer
################################################################################



struct OpenGLIndexBuffer <: IndexBuffer
    id::Ref{UInt32}
    length::Int
end

function IndexBuffer(indices)
    id = Ref{UInt32}()
    # No glCreateBuffer in ModernGL :(
    glGenBuffers(1, id)
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, id[])
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW)
    OpenGLIndexBuffer(id, length(indices))
end
bind(buffer::OpenGLIndexBuffer) = glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, buffer.id[])
unbind(buffer::OpenGLIndexBuffer) = glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0)
delete!(buffer::OpenGLIndexBuffer) = glDeleteBuffers(1, buffer.id)
Base.length(buffer::OpenGLIndexBuffer) = buffer.length
