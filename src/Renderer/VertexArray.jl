abstract type VertexArray end

function VertexArray(api::Type{<: RenderAPI})
    throw(ArgumentError("IndexBuffer not implemented for $api."))
end

struct OpenGLVertexArray <: VertexArray
    vbs::Vector{OpenGLVertexBuffer}
    ib::Ref{OpenGLIndexBuffer}
    id::Ref{UInt32}
end

function VertexArray(api::Type{OpenGL} = OpenGL)
    id = Ref{UInt32}()
    glGenVertexArrays(1, id)
    OpenGLVertexArray(OpenGLVertexBuffer[], Ref{OpenGLIndexBuffer}(), id)
end
bind(va::OpenGLVertexArray) = glBindVertexArray(va.id[])
unbind(va::OpenGLVertexArray) = glBindVertexArray(0)
delete!(va::OpenGLVertexArray) = glDeleteVertexArrays(1, va.id)

function Base.push!(va::OpenGLVertexArray, vb::OpenGLVertexBuffer)
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
function set!(va::OpenGLVertexArray, ib::OpenGLIndexBuffer)
    glBindVertexArray(va.id[])
    bind(ib)
    va.ib[] = ib
    nothing
end

vertex_buffers(va::OpenGLVertexArray) = va.vbs
index_buffer(va::OpenGLVertexArray) = va.ib[]
