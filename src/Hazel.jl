"""
A GameEngine project based on TheCherno's youtube series.

https://github.com/TheCherno/Hazel
https://www.youtube.com/playlist?list=PLlrATfBNZ98dC-V-N3m0Go4deliWHPFwT

The entrypoint to this module is `AbstractÀpplication`
"""
module Hazel

abstract type AbstractApplication end

# Maths
using LinearAlgebra
using Reexport
@reexport using GeometryTypes, Colors
# TODO
# - add Quarternions.jl?

# @backend macro
include("backend_error.jl")

# TODO
# figure out where to put this
# I guess it belongs to Inputs, but there is no folder for Inputs...
include("KeyCodes.jl")

# Events are passed around to notify stuff of other stuff
include("Events/Events.jl")

# Layers define renderorder
include("Layers/Layers.jl")

# Buffers, shaders, etc
include("Renderer/main.jl")

# A thing to render on
include("Window/Window.jl")



using GLFW, ModernGL
# OpenGL Implementations of stuff
include("OpenGL/OpenGL.jl")

using CImGui
include("Layers/ImGuiLayer.jl")


# An Application holds everything together
# TODO
# try to make stuff more generic, split generic stuff into files
include("Application/Application.jl")
export DummyApplication

end
