# Events

Events are used to dispatch actions made by the user to different parts of the application, mainly [Layers](@ref). The basic flow of events is as follows:
1. The [Window](@ref) catches backend events, creates the appropriate event `<: AbstractEvent` and calls `handle!(app, event)`.
2. The event is propagated to the window by calling `handle!(window, event)`. This may consume the event.
3. Remaining events are then propagated to layers by calling `handle!(layer, event)`. This happens in reverse rendering order and may consume events.
4. Any event that is left over is handed to `@debug`. This means that it will be printed if and only if the appropriate logging level is set.

It is simple to see that `handle!(..., event)` is the central function of this framework.

```@meta
CurrentModule = Hazel
```

```@doc
handle!(t::Any, e::AbstractEvent)
```

Note that events that have been "handled" are not propagated to any other levels.

There is a large number of event types that can be used. This, with Julias multiple dispatch, allows for a lot fo control over event handling.

## Event Type Tree

* AbstractEvent
  * ApplicationEvent
    * WindowEvent
      * WindowCloseEvent
      * WindowResizeEvent
      * WindowFocusEvent
      * WindowLostFocusEvent
      * WindowMovedEvent
    * AppTickEvent
    * AppUpdateEvent
    * AppRenderEvent
  * InputEvent
    * KeyboardEvent{keycode}
      * KeyPressedEvent{keycode}
      * KeyReleasedEvent{keycode}
    * MouseEvent
      * MouseButtonEvent{button}
        * MouseButtonPressedEvent{button}
        * MouseButtonReleasedEvent{button}
      * MouseScrolledEvent
      * MouseMovedEvent
