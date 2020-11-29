abstract type AbstractScene end

struct Scene <: AbstractScene
    registry::Ledger
    blank_texture::Texture2D
end

@HZ_profile function Scene()
    registry = Ledger()
    Scene(registry, Texture2D(fill(RGBA(1, 1, 1, 1), 1, 1)))
end

registry(scene::Scene) = scene.registry
Base.delete!(scene::Scene, e::Entity) = delete!(scene.registry, e)

# Overseer interface forwarding
Overseer.schedule_delete!(s::Scene, e::Entity) = schedule_delete!(s.registry, e)
Overseer.delete_scheduled!(s::Scene) = delete_Scheduled!(s.registry)
Base.setindex!(s::Scene, v, e::Entity) = s.registry[e] = v
Base.getindex(s::Scene, e::Entity) = s.registry[e]
Base.getindex(s::Scene, c::DataType) = s.registry[c]

@HZ_profile function render(scene::Scene)
    update(scene.registry)
end

"""
    blank_texture(scene)

Returns a 1x1 white Texture2D.
"""
function blank_texture(scene::Scene)
    scene.blank_texture
end

# This should all happen through finalizers I think
# function destroy(scene::Scene)
#     for component in scene.registry.components
#         for value in component
#             destroy(value)
#         end
#     end
#     for (_, stage) in scene.registry.stages
#         for system in stage
#             destroy(system)
#         end
#     end
#     destroy(scene.blank_texture)
# end

destroy(_) = nothing

Base.push!(scene::Scene, stage::Stage) = push!(scene.registry, stage)



function resize_viewport!(scene::Scene, w, h)
    cameras = scene[CameraComponent]
    for e in @entities_in(cameras)
        resize_viewport!(cameras[e], w, h)
    end
    nothing
end
