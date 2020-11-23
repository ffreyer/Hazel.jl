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
@reexport using GeometryBasics, Colors
using StaticArrays, Quaternions
using FileIO, ImageIO, FixedPointNumbers, ImageMagick # loading png files
using TimerOutputs
export print_timer, reset_timer!

using Overseer
import Overseer: update, requested_components


# projection math, LRBT, transformations
include("util/main.jl")
export LRBT, moveto!, moveby!, rotateto!, rotateby!, scaleto!, scaleby!

# currently just benchmarking/TimerOutputs extras
include("debug/Instrumentation.jl")
export @HZ_profile


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


using GLFW, ModernGL
# Window Implementation (and some event handling)
include("GLFW/GLFW.jl")
export WindowProperties, AbstractWindow, Window
export isopen, enable_vsync, disable_vsync, native_window
export keypressed, mousebutton_pressed, mouse_pos, mouse_x, mouse_y
# export GraphicsContext, init, swap_buffers, native_window


# OpenGL Implementations of stuff
include("OpenGL/OpenGL.jl")
# export gltype,
# export RenderCommand, clear, draw_indexed
export Shader, upload!
export VertexArray, vertex_buffer, index_buffer
export Texture2D
export BufferLayout, Normalize
# export offsets, types, name, offset, type, elsizeof, normalized # needed?
export AbstractGPUObject, AbstractGPUBuffer, bind, unbind
export AbstractVertexBuffer, layout, AbstractIndexBuffer


using CImGui
include("Layers/ImGuiLayer.jl")


# Buffers, shaders, etc
include("Renderer/main.jl")
export AbstractCamera, OrthographicCamera, OrthographicCameraController
export moveto!, moveby!, position, rotateto!, rotateby!, rotation, zoom, zoom!
export RegularSpriteSheet
# export projection, view, projection_view # Should these be exported?
export Scene, camera, render
export addQuad!, addBatchRenderingStage!, WrappedEntity, setcolor!






# An Application holds everything together
# TODO
# try to make stuff more generic, split generic stuff into files
include("Application/Application.jl")
export AbstractApplication, BasicApplication
export init!, destroy

const assetpath = joinpath((@__DIR__())[1:end-3], "assets")

end


# TODO Plan:
# - Cherno plans to make a Renderer2D
#   not sure if that's compatable with my stuff
#   might be better to have RenderObject2D and dispatch on that
# - GLAbstraction has a texture atlas :^)
# - video codec system :o
# - UI / Layouting
# - text rendering
# - post effects (bloom, color correction)
# - particle system

# TODO
# - make a Time struct with increasing time and delta time
#       struct Time{T}
#           time::T
#           delta::T
#       end
#       Base.(:+)(t::Time, dt) = Time(t.time + dt, dt)
#       etc
