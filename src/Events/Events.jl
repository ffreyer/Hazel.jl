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
struct WindowMinimizedEvent <: WindowEvent end
struct WindowRestoredEvent <: WindowEvent end

# TODO: 
# Abuse of dispatch -> move keycode to field?
struct KeyPressedEvent{keycode} <: KeyboardEvent{keycode}
    repeat_count::UInt32
    scancode::Cint
    mods::UInt8
end
struct KeyReleasedEvent{keycode} <: KeyboardEvent{keycode}
    scancode::Cint
    mods::UInt8
end


struct MouseMovedEvent <: MouseEvent
    x::Float64
    y::Float64
end
struct MouseScrolledEvent <: MouseEvent
    dx::Float64
    dy::Float64
end
struct MouseButtonPressedEvent{button} <: MouseButtonEvent{button}
    mods::Cint
end
struct MouseButtonReleasedEvent{button} <: MouseButtonEvent{button}
    mods::Cint
end

"""
    handle!(object, event)

Let `object` handle the `event`. May change the state of `object`. Returns true
if the `object` has been handled.
"""
function handle!(t::Any, e::AbstractEvent)
    @debug "Event $e targeted at $t has been discarded. (Missing method)"
    false
end

# Overloaded for ``@info obj` etc
Base.string(::T) where {T <: AbstractEvent} = string(T)
Base.string(e::MouseMovedEvent) = "MouseMovedEvent($(e.x), $(e.y))"
Base.string(e::MouseScrolledEvent) = "MouseScrolledEvent($(e.x_shift), $(e.y_shift))"
