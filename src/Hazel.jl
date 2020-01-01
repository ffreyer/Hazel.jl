"""
A GameEngine project based on TheCherno's youtube series.

https://github.com/TheCherno/Hazel
https://www.youtube.com/playlist?list=PLlrATfBNZ98dC-V-N3m0Go4deliWHPFwT

The entrypoint to this module is `AbstractÀpplication`
"""
module Hazel

include("Events/Events.jl")

include("Layers/Layers.jl")

using GLFW
include("Window/Window.jl")

include("Application.jl")
export DummyApplication

end

# TODO
# - change on_update to update
# - maybe change on_event to process_event? or just process?
# - DummyApplication -> Application, remove abstract? or
#   make methods implementations of AbstractApplication
# - change events: no handled, but on_event should return true if the event
#   has been dealt with
# - Remove on_ from AbstractLayer functions
