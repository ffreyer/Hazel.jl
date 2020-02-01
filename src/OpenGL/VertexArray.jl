struct VertexArray <: AbstractVertexArray
    vbs::Vector{VertexBuffer}
    ib::Ref{IndexBuffer}
    id::Ref{UInt32}
end

"""
    VertexArray()

Constructs a VertexArray.

# Warning

There is explicit cleanup required! Call ´destroy(vertex_array)´ to remove it
from the gpu.
"""
function VertexArray()
    id = Ref{UInt32}()
    glGenVertexArrays(1, id)
    VertexArray(VertexBuffer[], Ref{IndexBuffer}(), id)
end
bind(va::VertexArray) = glBindVertexArray(va.id[])
unbind(va::VertexArray) = glBindVertexArray(0)
delete!(va::VertexArray) = glDeleteVertexArrays(1, va.id)

function Base.push!(va::VertexArray, vb::VertexBuffer)
    push!(va.vbs, vb)
    glBindVertexArray(va.id[])
    bind(vb)
    for (i, element) in enumerate(getlayout(vb))
        glEnableVertexAttribArray(i-1)
        glVertexAttribPointer(
            i-1,                            # index of Layout element :: Integer
            length(element),                # length of layout element :: Integer
            gltype(eltype(element)),        # element type :: GLEnum (GL_FLOAT)
            gltype(normalized(element)),    # normalized :: GLEnum (GL_TRUE / GL_FALSE)
            sizeof(getlayout(vb)),                 # total vertex size :: Integer
            Ptr{Nothing}(offset(element))   # offset in array :: Pointer? Why not Integer?
        )
    end
    nothing
end
function set!(va::VertexArray, ib::IndexBuffer)
    glBindVertexArray(va.id[])
    bind(ib)
    va.ib[] = ib
    nothing
end

vertex_buffers(va::VertexArray) = va.vbs
index_buffer(va::VertexArray) = va.ib[]
