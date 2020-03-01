# convenience wrappers for enum transformation
Action(x::GLFW.Action) = Action(Cint(x))
Key(x::GLFW.Key) = Key(Cint(x))
MouseButton(x::GLFW.MouseButton) = MouseButton(Cint(x))
Joystick(x::GLFW.Joystick) = Joystick(Cint(x))

# GLFW Window construction + some event callbacks/handling
include("GraphicsContext.jl")
include("Window.jl")
include("Inputs.jl")
