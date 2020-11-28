include("Camera/Camera.jl")

# "high"-level Renderer implementation
include("SubTexture2D.jl")

# ECS related (core)
include("Scene.jl")
include("components.jl")
include("entity_wrapper.jl")
include("camera.jl")

# special stuff
include("batch_rendering.jl")

# old
# include("Scene.jl")
# include("Renderer/Renderer.jl")
# include("Renderer2D/Renderer2D.jl")
