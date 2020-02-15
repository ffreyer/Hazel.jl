# TODO
# Does this need to be able to have multiple vertex buffers? index buffers?
struct VertexArray <: AbstractVertexArray
    vb::VertexBuffer
    ib::IndexBuffer
    id::Ref{UInt32}
end

"""
    VertexArray(vertex_buffer, index_buffer)

Constructs a VertexArray from `vertex_buffer` and `index_buffer`

# Warning

There is explicit cleanup required! Call ´destroy(vertex_array)´ to remove it
from the gpu.
"""
function VertexArray(vertex_buffer::VertexBuffer, index_buffer::IndexBuffer)
    id = Ref{UInt32}()
    glGenVertexArrays(1, id)

    glBindVertexArray(id[])
    let
        vb = vertex_buffer
        bind(vb)
        for (i, element) in enumerate(getlayout(vb))
            glEnableVertexAttribArray(i-1)
            glVertexAttribPointer(
                i-1,                            # index of Layout element :: Integer
                length(element),                # length of layout element :: Integer
                gltype(eltype(element)),        # element type :: GLEnum (GL_FLOAT)
                gltype(normalized(element)),    # normalized :: GLEnum (GL_TRUE / GL_FALSE)
                sizeof(getlayout(vb)),          # total vertex size :: Integer
                Ptr{Nothing}(offset(element))   # offset in array :: Pointer? Why not Integer?
            )
        end
    end
    bind(index_buffer)

    VertexArray(vertex_buffer, index_buffer, id)
end
bind(va::VertexArray) = glBindVertexArray(va.id[])
unbind(va::VertexArray) = glBindVertexArray(0)
destroy(va::VertexArray) = glDeleteVertexArrays(1, va.id)
vertex_buffer(va::VertexArray) = va.vb
index_buffer(va::VertexArray) = va.ib
