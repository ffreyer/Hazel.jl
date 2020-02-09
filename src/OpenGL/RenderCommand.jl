"""
    RenderCommand

RenderCommand is a `module` that contains "low"-level render calls.

#### Functions:
- `clear([color])`: Clears the screen with given color.
- `draw_indexed(va::VertexArray)`: Draws a vertex array. (Does not bind)
"""
struct OpenGLRenderCommand <: AbstractRenderCommand end
const RenderCommand = OpenGLRenderCommand()

clear(r::OpenGLRenderCommand, color::Colorant) = clear(r, RGBA(color))
function clear(::OpenGLRenderCommand, color::RGBA = RGBA(0.1, 0.1, 0.1, 1.0))
    glClearColor(color.r, color.g , color.b, color.alpha)
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
end

function draw_indexed(::OpenGLRenderCommand, va::VertexArray)
    glDrawElements(
        GL_TRIANGLES,
        length(index_buffer(va)),
        GL_UNSIGNED_INT,
        C_NULL
    )
end
