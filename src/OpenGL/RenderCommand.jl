"""
    RenderCommand

RenderCommand is a `module` that contains "low"-level render calls.

#### Functions:
- `clear([color])`: Clears the screen with given color.
- `draw_indexed(va::VertexArray)`: Draws a vertex array. (Does not bind)
"""
module RenderCommand

using ..Hazel
using ..Hazel.ModernGL, ..Hazel.Colors
# struct OpenGLRenderCommand <: AbstractRenderCommand end
# const RenderCommand = OpenGLRenderCommand()

function init!()
    glEnable(GL_BLEND)
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    glEnable(GL_DEPTH_TEST)
end

"""
    clear(::RenderCommand, color = :white <: Colorant)

Clears the screen with a specific `color`.
"""
clear(color::Colorant) = clear(r, RGBA(color))
@HZ_profile function clear(color::RGBA = RGBA(0.1, 0.1, 0.1, 1.0))
    glClearColor(color.r, color.g , color.b, color.alpha)
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
end

"""
    draw_indexed(::RenderCommand, vertex_array[, length=length(index_buffer)])

Draw a given `vertex_array`.
"""
@HZ_profile function draw_indexed(
        va::Hazel.VertexArray,
        length = length(Hazel.index_buffer(va))
    )
    glDrawElements(GL_TRIANGLES, length, GL_UNSIGNED_INT, C_NULL)
end

viewport(x, y, w, h) = glViewport(x, y, w, h)

end
