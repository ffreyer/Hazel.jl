# GLFW

The GLFW directory implements a GLFW backend for `Window`s and event creation.

## Window.jl

Implements

```@doc
"""
    Window(properties::WindowProperties, event_callback::Function[, vsync = true])
    Window(event_callback::Function[, vsync = true, name = "Hazel Engine", widht=1280, height=720])

Creates a new Window with the give `properties` and event callback function
`event_callback`.

# Warning

There is explicit cleanup required! Call destroy(window)´ to destroy the window.
"""
```

## GraphicsContext.jl

## Inputs.jl
