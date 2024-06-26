abstract type AbstractScene end

struct Scene <: AbstractScene
    registry::Overseer.Ledger
    blank_texture::Texture2D
end

@HZ_profile function Scene()
    registry = Overseer.Ledger()
    Scene(registry, Texture2D(fill(RGBA(1, 1, 1, 1), 1, 1)))
end

"""
    blank_texture(scene)

Returns a 1x1 white Texture2D.
"""
blank_texture(scene::Scene) = scene.blank_texture

destroy(_) = nothing

update!(app, scene::Scene, ts) = update_runtime!(app, scene, ts)
@HZ_profile function update_runtime!(app, scene::Scene, ts)
    update_runtime!(app, scene.registry, ts)
end
@HZ_profile function update_editor!(app, scene::Scene, camera::EditorCamera, ts)
    update_editor!(app, scene.registry, camera, ts)
end

Base.push!(scene::Scene, stage::Stage) = push!(scene.registry, stage)

registry(scene::Scene) = scene.registry
Base.delete!(scene::Scene, e::RawEntity) = delete!(scene.registry, e)

# Overseer interface forwarding
Overseer.schedule_delete!(s::Scene, e::RawEntity) = Overseer.schedule_delete!(s.registry, e)
Overseer.delete_scheduled!(s::Scene) = Overseer.delete_Scheduled!(s.registry)
Base.setindex!(s::Scene, v, e::RawEntity) = s.registry[e] = v
Base.getindex(s::Scene, e::RawEntity) = s.registry[e]
Base.getindex(s::Scene, c::DataType) = s.registry[c]

Overseer.components(scene::Scene)       = Overseer.components(registry(scene))
Overseer.entities(scene::Scene)         = map(e -> Entity(scene, e), Overseer.entities(registry(scene)))
Overseer.free_entities(scene::Scene)    = map(e -> Entity(scene, e), Overseer.free_entities(registry(scene)))
Overseer.valid_entities(scene::Scene)   = map(e -> Entity(scene, e), Overseer.valid_entities(registry(scene)))
Overseer.to_delete(scene::Scene)        = Overseer.to_delete(registry(scene))
Overseer.stages(scene::Scene)           = Overseer.stages(registry(scene))
Overseer.stage(scene::Scene, s::Symbol) = Overseer.stage(registry(scene), s)
Overseer.groups(scene::Scene)           = Overseer.groups(registry(scene))

Base.delete!(scene::Scene, e::AbstractEntity) = delete!(scene.registry, RawEntity(e))
function Overseer.schedule_delete!(s::Scene, e::AbstractEntity)
    Overseer.schedule_delete!(s.registry, entity(e))
end
Base.setindex!(s::Scene, v, e::AbstractEntity) = s.registry[entity(e)] = v
Base.getindex(s::Scene, e::AbstractEntity) = s.registry[entity(e)]




function resize_viewport!(scene::Scene, w, h)
    ccs = scene[CameraComponent]
    for e in @entities_in(ccs)
        if !ccs[e].fix_aspect_ratio
            ccs[e].aspect = Float32(w/h)
        end
    end
    nothing
end



################################################################################
### Scene related ECS extensions
################################################################################



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
