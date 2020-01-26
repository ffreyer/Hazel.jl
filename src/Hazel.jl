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
using GeometryTypes
# TODO
# - add Colors.jl?
# - add Quarternions.jl?


# TODO
# figure out where to put this
# I guess it belongs to Inputs, but there is no folder for Inputs...
include("KeyCodes.jl")
include("gl_utils.jl")

# Events are passed around to notify stuff of other stuff
include("Events/Events.jl")

# Layers define renderorder
include("Layers/Layers.jl")

# A thing to render on
using GLFW, ModernGL
include("Renderer/Renderer.jl")
include("Window/Window.jl")

# TODO
# probably need to call CImGui's callback functions?
using CImGui
include("Layers/ImGuiLayer.jl")


# An Application holds everything together
# TODO
# try to make stuff more generic, split generic stuff into files
include("Application/Application.jl")
export DummyApplication

end
