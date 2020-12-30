# include("Camera/Camera.jl")

# "high"-level Renderer implementation
include("SubTexture2D.jl")

include("EditorCamera.jl")

# ECS related (core - wrappers and functionality)
include("entity_wrapper.jl")
include("systems.jl")

# Making use of the ECS
# generic components
include("components.jl")
# more or less a registry wrapper
include("Scene.jl")
# Camera entity, components and system
include("camera.jl")
# batch rendering - Quad entity, components and systems
include("batch_rendering.jl")

include("serialization.jl")

# old
# include("Scene.jl")
# include("Renderer/Renderer.jl")
# include("Renderer2D/Renderer2D.jl")
