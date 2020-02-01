abstract type GraphicsContext end


"""
    GraphicsContext(native_window)

Creates a `GraphicsContext` which handles interactions with the window api.
"""
@backend GraphicsContext

"""
    init(graphics_context)

Initializes the given `graphics_context`.
"""
@backend init(context::GraphicsContext)

"""
    swap_buffers(graphics_context)

Swaps the buffers of the given `graphics_context`
"""
@backend swap_buffers(context::GraphicsContext)

"""
    native_window(graphics_context)

Returns the native window of the given `graphics_context`
"""
@backend native_window(context::GraphicsContext)
