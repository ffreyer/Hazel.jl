################################################################################
### VertexBuffer Implementation
################################################################################


struct VertexBuffer <: AbstractVertexBuffer
    # TODO can this be UInt32?
    # Needs to be reference in delete!
    # but can we remake that reference on the fly? Or use a Pointer
    id::Ref{UInt32}
    layout::LazyBufferLayout
end

"""
    VertexBuffer(vertices, layout::BufferLayout)

Constructs a VertexBuffer with the given `vertices` and `layout`.

# Warning

There is explicit cleanup required! Call ´destroy(vertex_buffer)´ to remove it
from the gpu.
"""
function VertexBuffer(vertices, layout::BufferLayout)
    id = Ref{UInt32}()
    # No glCreateBuffer in ModernGL :(
    glGenBuffers(1, id)
    glBindBuffer(GL_ARRAY_BUFFER, id[])
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW)
    VertexBuffer(id, layout)
end
bind(buffer::VertexBuffer) = glBindBuffer(GL_ARRAY_BUFFER, buffer.id[])
unbind(buffer::VertexBuffer) = glBindBuffer(GL_ARRAY_BUFFER, 0)
destroy(buffer::VertexBuffer) = glDeleteBuffers(1, buffer.id)
getlayout(vb::VertexBuffer) = vb.layout


################################################################################
### IndexBuffer Implementation
################################################################################


struct IndexBuffer <: AbstractIndexBuffer
    id::Ref{UInt32}
    length::Int
end

"""
    IndexBuffer(indices)

Constructs a IndexBuffer with the given `indices`.

# Warning

There is explicit cleanup required! Call ´delete!(index_buffer)´ to remove it
from the gpu.
"""
function IndexBuffer(indices)
    id = Ref{UInt32}()
    # No glCreateBuffer in ModernGL :(
    glGenBuffers(1, id)
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, id[])
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW)
    IndexBuffer(id, length(indices))
end
bind(buffer::IndexBuffer) = glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, buffer.id[])
unbind(buffer::IndexBuffer) = glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0)
destroy(buffer::IndexBuffer) = glDeleteBuffers(1, buffer.id)
Base.length(buffer::IndexBuffer) = buffer.length