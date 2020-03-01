"""
A GameEngine project based on TheCherno's youtube series.

https://github.com/TheCherno/Hazel
https://www.youtube.com/playlist?list=PLlrATfBNZ98dC-V-N3m0Go4deliWHPFwT
"""
module Hazel

abstract type AbstractApplication end

# Maths
using LinearAlgebra
using Reexport
@reexport using GeometryTypes, Colors
using StaticArrays, Quaternions

# projection stuff
include("math/math.jl")

# @backend macro
include("backend_error.jl")

# TODO
# figure out where to put this
# I guess it belongs to Inputs, but there is no folder for Inputs...
include("KeyCodes.jl")
export Action, Key, MouseButton, Joystick
export MOD_SHIFT, MOD_CONTROL, MOD_ALT, MOD_SUPER
export MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE


# Events are passed around to notify stuff of other stuff
include("Events/Events.jl")
export AbstractEvent
export ApplicationEvent, WindowEvent, InputEvent, KeyboardEvent, MouseEvent, MouseButtonEvent
export AppTickEvent, AppUpdateEvent, AppRenderEvent
export WindowCloseEvent, WindowResizeEvent, WindowFocusEvent, WindowLostFocusEvent, WindowMovedEvent
export KeyPressedEvent, KeyReleasedEvent
export MouseMovedEvent, MouseScrolledEvent, MouseButtonPressedEvent, MouseButtonReleasedEvent
export handle!


# Layers define renderorder
include("Layers/Layers.jl")
export AbstractLayer, ImGuiLayer
export attach, detach, update!
export MutableLayerStack, StaticLayerStack
export push_overlay!, pop_overlay!


# Buffers, shaders, etc
include("Renderer/main.jl")
export AbstractCamera, OrthographicCamera
export moveto!, moveby!, position, rotateto!, rotateby!, rotation
# projection, view, projection_view # Should these be exported?
export AbstractGPUObject, AbstractGPUBuffer, bind, unbind
export AbstractVertexBuffer, layout, AbstractIndexBuffer
export BufferLayout, Normalize
#export offsets, types, name, offset, type, elsizeof, normalized # needed?
#export GraphicsContext, init, swap_buffers, native_window
export Renderer, submit
# export clear, draw_indexed
export RenderObject, Scene, camera
export Shader, upload!
export VertexArray, vertex_buffer, index_buffer


# A thing to render on
include("Window/Window.jl")
export WindowProperties, AbstractWindow, Window
export isopen, enable_vsync, disable_vsync, native_window


using GLFW, ModernGL
# Window Implementation (and some event handling)
include("GLFW/GLFW.jl")
export keypressed, mousebutton_pressed, mouse_pos, mouse_x, mouse_y


# OpenGL Implementations of stuff
include("OpenGL/OpenGL.jl")
# export gltype,
# export RenderCommand, clear, draw_indexed


using CImGui
include("Layers/ImGuiLayer.jl")


# An Application holds everything together
# TODO
# try to make stuff more generic, split generic stuff into files
include("Application/Application.jl")
export AbstractApplication, BasicApplication
export init!, destroy


end
