"""
Events are currently designed with multiple dispatch in mind. Functions that
process Events should generally take the form `foo(::EventType)` where
`EventType` is some type of event.

For example, writing a specific key to the console might be
```
log_event(io::IO, ::KeyPressedEvent{Key.A}) = @info "Key <A> has been pressed!"
```

## Type Tree

AbstractEvent
    ApplicationEvent
        WindowEvent
            WindowCloseEvent
            WindowResizeEvent
            WindowFocusEvent
            WindowLostFocusEvent
            WindowMovedEvent
        AppTickEvent
        AppUpdateEvent
        AppRenderEvent
    InputEvent
        KeyboardEvent{keycode}
            KeyPressedEvent{keycode}
            KeyReleasedEvent{keycode}
        MouseEvent
            MouseButtonEvent{button}
                MouseButtonPressedEvent{button}
                MouseButtonReleasedEvent{button}
            MouseScrolledEvent
            MouseMovedEvent
"""
abstract type AbstractEvent end

abstract type ApplicationEvent <: AbstractEvent end
abstract type WindowEvent <: ApplicationEvent end
abstract type InputEvent <: AbstractEvent end
abstract type KeyboardEvent{keycode} <: InputEvent end
abstract type MouseEvent <: InputEvent end
abstract type MouseButtonEvent{button} <: MouseEvent end


struct AppTickEvent <: ApplicationEvent end
struct AppUpdateEvent <: ApplicationEvent end
struct AppRenderEvent <: ApplicationEvent end


struct WindowCloseEvent <: WindowEvent end
struct WindowResizeEvent <: WindowEvent
    width::Int64
    height::Int64
end
struct WindowFocusEvent <: WindowEvent end
struct WindowLostFocusEvent <: WindowEvent end
struct WindowMovedEvent <: WindowEvent end


struct KeyPressedEvent{keycode} <: KeyboardEvent{keycode}
    repeat_count::UInt32
end
struct KeyReleasedEvent{keycode} <: KeyboardEvent{keycode} end


struct MouseMovedEvent <: MouseEvent
    x::Int64
    y::Int64
end
struct MouseScrolledEvent <: MouseEvent
    x_shift::Int64
    y_shift::Int64
end
struct MouseButtonPressedEvent{button} <: MouseButtonEvent{button} end
struct MouseButtonReleasedEvent{button} <: MouseButtonEvent{button} end
