abstract type AbstractScene end

struct Scene <: AbstractScene
    registry::Ledger
end

@HZ_profile function Scene()
    registry = Ledger()
    Scene(registry)
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

function destroy(scene::Scene)
    for component in scene.registry.components
        for value in component
            destroy(value)
        end
    end
    for (_, stage) in scene.registry.stages
        for system in stage
            destroy(system)
        end
    end
end

destroy(_) = nothing

Base.push!(scene::Scene, stage::Stage) = push!(scene.registry, stage)