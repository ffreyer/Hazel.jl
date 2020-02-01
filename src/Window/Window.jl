# No point in this if it's not mutable
mutable struct WindowProperties
    title::String
    width::UInt32
    height::UInt32
    isopen::Bool
end

"""
    WindowProperties()

Creates a `WindowProperties` object, which contains the window title, the
current width, height and whether the window is currently open.

#### Keyword Arguments:
- `title = "Hazel Engine"`: The title of the window.
- `width = 1280`: The width of the window.
- `height = 720`: The height of the window.
- `isopen = true`: Whether the window is open.
"""
function WindowProperties(;
        title = "Hazel Engine",
        width = 1280,
        height = 720,
        isopen = true
    )
    new(title, width, height, isopen)
end


abstract type AbstractWindow end


# Window

"""
    destroy(window)

Destroy the given `window`.
"""
@backend destroy(window::AbstractWindow)

"""
    isopen(window)

Returns true if the window is open.
"""
@backend isopen

"""
    enable_vsync(window)

Enables vsync for the given `window`.
"""
@backend enable_vsync

"""
    disable_vsync(window)

Disables vsync for the given `window`.
"""
@backend disable_vsync

"""
    update!(window)

Updates the given `window`. This includes polling events and swapping buffers.
"""
@backend update!

"""
    native_window(window)

Returns the native window of the given `Window`.
"""
@backend native_window
