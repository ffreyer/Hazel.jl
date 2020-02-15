# Window

`Window` is planned to be a backend independent wrapper for windows. Currently it only implements GLFW windows. (And this may never change.) It currently consists of

```@meta
CurrentModule = Hazel
```

```@docs
WindowProperties
```

and a `GLFWGraphicsContext`. It implements

```@docs
destroy(window::AbstractWindow)
isopen
enable_vsync
disable_vsync
update!(window::AbstractWindow)
native_window(window::AbstractWindow)
```

More on the implementation in GLFW(...)
