################################################################################
### EntityComponentSystem
################################################################################

# What we want:
# - grouped components, e.g. a list of all mesh components for easy/fast rendering

# Design:
# - Each Component type is a unique struct
# - there's an ECS type which has a list for each component type (maybe dict of lists?)
# - An Entity is...
#   - an ID (Int) and each Component has a ID which ties it to that entity 
#     (requires search)  <-- doing this for now *
#   - a collection of IDs which refer to indices in component lists (requires 
#     many updates on delete)
#   - a collection of references/pointers (probably best?)
#   * only allow IDs to increase, and always append component lists
#     => component lists sorted, can fast search


# How it's used:
# ecs = EntityComponentSystem()
#   e = Entity(ecs, "MyEntity") # attaches entity
#   Component(ecs, e, ...) # attaches component to both

# naming could use some work I guess?

struct EntityComponentSystem
    max_ID::Ref{UInt64}
    entities::Vector{Entity}
    components::Dict{Symbol, Vector}
end

function EntityComponentSystem()
    EntityComponentSystem(
        Ref{UInt64}(0), Vector{Entity}(), Dict{Symbol, Vector}()
    )
end

function component(ecs::EntityComponentSystem, key, target_id::UInt64)
    components = ecs.components[key]
    find_id(components, 1, length(components), target_id)
end

function find_id(components, low, high, target_id, threshhold=20)
    if high - low < threshhold
        return linear_search(components, low, high, target_id)
    end

    # Estimate index
    low_id = components[low].id
    high_id = components[high].id
    idx = trunc(Int, (target_id-low_id) / (high_id-low_id) * (high-low) + low)
    
    id = components[idx].id
    if id == target_id
        return components[idx]
    elseif id < target_id
        return find_id(components, idx, high, target_id, threshhold)
    else
        return find_id(components, low, idx, target_id, threshhold)
    end
end

function linear_search(components, low, high, target_id)
    for idx in low:high
        if components[idx].id == target_id
            return components[idx]
        end
    end
    error("This should be unreachable.")
end



################################################################################
### Entity
################################################################################

# Entity:
# - A collection of components
# - maybe change components in entities to pointers/refs?



struct Entity
    name::String
    ID::UInt64
    ecs::EntityComponentSystem
    components::Vector{Symbol}
end

function Entity(ecs::EntityComponentSystem, name::String)
    ID = ecs.max_ID[]
    ecs.max_ID[] += 1
    e = Entity(name, ID, ecs, Vector{Symbol}())
    push!(entities, e)
    e
end

# Do I want this? I assume this kinda sucks for performance?
@inline function Base.getproperty(e::Entity, key::Symbol)
    if key in (:name, :ID, :ecs)
        getfield(e, key)
    elseif haskey(e.components, key)
        component(e.ecs, key, e.ID)
    end
end



################################################################################
### Components
################################################################################


# Component:
# - Things an entity may have, like a mesh, Audio, a script, etc
# - Maybe add more subtyping, i.e. RenderComponent etc?


abstract type AbstractComponent end

struct DummyComponent <: AbstractComponent
    ID::UInt64
end

function DummyComponent(ecs::EntityComponentSystem, e::Entity)
    ID = e.ID
    c = DummyComponent(ID)
    if !haskey(ecs.components, :DummyComponent)
        push!(ecs.components, :DummyComponent => Vector{DummyComponent}())
    end
    push!(ecs.components[:DummyComponent], c)
    push!(e.components, :DummyComponent)
    c
end

# nameof(DummyComponent) = :DummyComponent