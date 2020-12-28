abstract type AbstractScene end

struct Scene <: AbstractScene
    viewport_size::Vector{Int}
    registry::Overseer.Ledger
    blank_texture::Texture2D
end

@HZ_profile function Scene()
    registry = Overseer.Ledger()
    Scene(registry, Texture2D(fill(RGBA(1, 1, 1, 1), 1, 1)))
end

registry(scene::Scene) = scene.registry
Base.delete!(scene::Scene, e::RawEntity) = delete!(scene.registry, e)

# Overseer interface forwarding
Overseer.schedule_delete!(s::Scene, e::RawEntity) = Overseer.schedule_delete!(s.registry, e)
Overseer.delete_scheduled!(s::Scene) = Overseer.delete_Scheduled!(s.registry)
Base.setindex!(s::Scene, v, e::RawEntity) = s.registry[e] = v
Base.getindex(s::Scene, e::RawEntity) = s.registry[e]
Base.getindex(s::Scene, c::DataType) = s.registry[c]

@HZ_profile function update!(app, scene::Scene, ts)
    update!(app, scene.registry, ts)
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
    ccs = scene[CameraComponent]
    for e in @entities_in(ccs)
        ccs[e].aspect = Float32(w/h)
    end
    nothing
end



################################################################################
### Scene related ECS extensions
################################################################################


Base.delete!(scene::Scene, e::AbstractEntity) = delete!(scene.registry, RawEntity(e))
function Overseer.schedule_delete!(s::Scene, e::AbstractEntity)
    Overseer.schedule_delete!(s.registry, entity(e))
end
Base.setindex!(s::Scene, v, e::AbstractEntity) = s.registry[entity(e)] = v
Base.getindex(s::Scene, e::AbstractEntity) = s.registry[entity(e)]



"""
    RawEntity(e::AbstractEntity)
    RawEntity(reg::Overseer.Ledger, components...)
    RawEntity(scene::Scene, components...)

Creates (or retrieves) a `RawEntity` which is an alias for `Overseer.Entity`.
"""
function RawEntity(scene::Scene, components...)
    RawEntity(registry(scene), components...)
end



Entity(scene::Scene, e::RawEntity) = Entity(registry(scene), e)
function Entity(scene::Scene, components...)
    Entity(registry(scene), RawEntity(registry(scene), components...))
end



struct SceneEntity <: AbstractEntity
    scene::Scene
    entity::RawEntity
end

"""
    SceneEntity(scene::Scene, entity::RawEntity)
    SceneEntity(scene::Scene, components...)

Creates an `Entity` which wraps the scene to simplify modification.
For example, it simplifies `registry(scene)[Component][entity]` to 
`entity[Component]`.

If a set of components is passed instead of a raw entity, a new entity will be 
created and embeded in the passed scene.
"""
function SceneEntity(scene::Scene, components...)
    SceneEntity(scene, RawEntity(registry(scene), components...))
end
@inline registry(e::SceneEntity) = registy(e.scene)
