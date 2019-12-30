"""
A GameEngine project based on TheCherno's youtube series.

https://github.com/TheCherno/Hazel
https://www.youtube.com/playlist?list=PLlrATfBNZ98dC-V-N3m0Go4deliWHPFwT

The entrypoint to this module is `AbstractÀpplication`
"""
module Hazel


include("Events/Events.jl")

using GLFW
include("Window/Window.jl")

include("Application.jl")
export DummyApplication

end
