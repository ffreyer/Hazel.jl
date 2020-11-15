# TODO
# merge this into Renderer/Scene
include("components.jl")

struct Scene
    ecs::Registry
end

Scene() = Scene(Registry())

# function Hazel.update!(l::EditorLayer, dt)
function update!(s::Scene, dt)
    for (transform, sprite) in group(registry, :transform, :sprite)
        # this would fit better if we did robj, transform
        Renderer2D.submit(sprite, transform)
        # Renderer2D.draw_quad(sprite, transform)
    end
end

Entity(scene::Scene) = Entity(scene.ecs)
registry(scene::Scene) = scene.ecs