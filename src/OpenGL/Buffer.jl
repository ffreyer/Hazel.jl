################################################################################
### VertexBuffer Implementation
################################################################################


mutable struct VertexBuffer <: AbstractVertexBuffer
    # TODO can this be UInt32?
    # Needs to be reference in delete!
    # but can we remake that reference on the fly? Or use a Pointer
    id::UInt32
    layout::LazyBufferLayout
end

"""
    VertexBuffer(vertices, layout::BufferLayout)

Constructs a VertexBuffer with the given `vertices` and `layout`.

# Warning

There is explicit cleanup required! Call ´destroy(vertex_buffer)´ to remove it
from the gpu.
"""
@HZ_profile function VertexBuffer(vertices::AbstractArray, layout::BufferLayout)
    id = Ref{UInt32}()
    # No glCreateBuffer in ModernGL :(
    glGenBuffers(1, id)
    glBindBuffer(GL_ARRAY_BUFFER, id[])
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW)
    finalizer(destroy, VertexBuffer(id[], layout))
end
"""
    VertexBuffer(length::Integer, layout::BufferLayout)

length is the number of vertices, so multiplied by sizeof(layout)
"""
@HZ_profile function VertexBuffer(length::Integer, layout::BufferLayout)
    id = Ref{UInt32}()
    glGenBuffers(1, id)
    glBindBuffer(GL_ARRAY_BUFFER, id[])
    glBufferData(GL_ARRAY_BUFFER, sizeof(layout) * length, C_NULL, GL_DYNAMIC_DRAW)
    finalizer(destroy, VertexBuffer(id[], layout))
end
@HZ_profile bind(buffer::VertexBuffer) = glBindBuffer(GL_ARRAY_BUFFER, buffer.id)
@HZ_profile unbind(buffer::VertexBuffer) = glBindBuffer(GL_ARRAY_BUFFER, 0)
destroy(buffer::VertexBuffer) = glDeleteBuffers(1, Ref(buffer.id))
"""
    layout(vertex_buffer)

Returns the layout attached to the given `vertex_buffer`
"""
layout(vb::VertexBuffer) = vb.layout

function upload!(vb::VertexBuffer, vertices::AbstractArray)
    bind(vb)
    glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(vertices), vertices)
end


################################################################################
### IndexBuffer Implementation
################################################################################


mutable struct IndexBuffer <: AbstractIndexBuffer
    id::UInt32
    length::Int
end

"""
    IndexBuffer(indices)

Constructs a IndexBuffer with the given `indices`.

# Warning

There is explicit cleanup required! Call ´delete!(index_buffer)´ to remove it
from the gpu.
"""
@HZ_profile function IndexBuffer(indices)
    id = Ref{UInt32}()
    # No glCreateBuffer in ModernGL :(
    glGenBuffers(1, id)
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, id[])
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW)
    finalizer(destroy, IndexBuffer(id[], length(indices)))
end
@HZ_profile bind(buffer::IndexBuffer) = glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, buffer.id)
@HZ_profile unbind(buffer::IndexBuffer) = glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0)
destroy(buffer::IndexBuffer) = glDeleteBuffers(1, Ref(buffer.id))
Base.length(buffer::IndexBuffer) = buffer.length
