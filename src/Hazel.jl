"""
A GameEngine project based on TheCherno's youtube series.

https://github.com/TheCherno/Hazel
https://www.youtube.com/playlist?list=PLlrATfBNZ98dC-V-N3m0Go4deliWHPFwT

The entrypoint to this module is `AbstractÀpplication`
"""
module Hazel

# sad GUI noises

# Events are passed around to notify stuff of other stuff
include("Events/Events.jl")

# Layers define renderorder
include("Layers/Layers.jl")

# A thing to render on
using GLFW, ModernGL
include("Window/Window.jl")

# An Application holds everything together
# TODO
# try to make stuff more generic, split generic stuff into files
include("Application/Application.jl")
export DummyApplication

end
