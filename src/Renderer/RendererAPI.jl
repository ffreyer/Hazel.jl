abstract type AbstractRendererAPI end


"""
    RendererAPI()

Creates a `RendererAPI` which handles draw calls.
"""
@backend RendererAPI

"""
    clear(::RendererAPI, color <: Colorant)

Clears the screen with a specific `color`.
"""
@backend clear(::RendererAPI, color::Colorant)

"""
    draw_indexed(::RendererAPI, vertex_array)

Draw a given `vertex_array`.
"""
@backend draw_indexed(::RendererAPI, vertex_array)
