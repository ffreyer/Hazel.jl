# What we want:
# - grouped components, e.g. a list of all mesh components for easy/fast rendering

# Prolly outdated:
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
# ecs = Registry()
#   e = Entity(ecs, "MyEntity") # attaches entity
#   Component(ecs, e, ...) # attaches component to both



################################################################################
### ComponentVector
################################################################################



# This wrapper gives us a few things:
# - separate vectors should speed up search and direct iteration
# - we can forward getindex and iteration to return just components
struct ComponentVector{T}
    IDs::Vector{UInt64}
    components::Vector{T}
end

ComponentVector{T}() = ComponentVector(UInt64[], T[])

Base.getindex(cv::ComponentVector, i) = cv.components[i]
Base.iterate(cv::ComponentVector) = iterate(cv.components)



################################################################################
### Registry / Entity Component System
################################################################################



struct Registry
    max_ID::Ref{UInt64}
    entities::Vector{Entity}
    components::Dict{Symbol, ComponentVector}
end

function Registry()
    Registry(Ref{UInt64}(0), Vector{Entity}(), Dict{Symbol, ComponentVector}())
end


# Component search by ID
function component(ecs::Registry, key::Symbol, target_id::UInt64)
    components = ecs.components[key]
    idx = find_id(components.IDs, 1, length(components), target_id)
    components.components[idx]
end

function find_id(IDs, low, high, target_id, threshhold=20)
    if high - low < threshhold
        return linear_search(IDs, low, high, target_id)
    end

    # Estimate index
    low_id = IDs[low]
    high_id = IDs[high]
    idx = trunc(Int, (target_id-low_id) / (high_id-low_id) * (high-low) + low)
    
    id = IDs[idx]
    if id == target_id
        return IDs[idx]
    elseif id < target_id
        return find_id(IDs, idx, high, target_id, threshhold)
    else
        return find_id(IDs, low, idx, target_id, threshhold)
    end
end

function linear_search(IDs, low, high, target_id)
    for idx in low:high
        if IDs[idx] == target_id
            return IDs[idx]
        end
    end
    ErrorException(
        "Entity ID $target_id not found in component list. [..., $(IDs[low:high]), ...]"
    )
end


# for c in ecs[:mycomponent]
Base.getindex(ecs::Registry, key::Symbol) = ecs.components[key]
Base.keys(ecs::Registry) = keys(ecs.components)
Base.haskey(ecs::Registry, key::Symbol) = haskey(ecs.components, key)


function Base.push!(ecs::Registry, key::Symbol, ID::UInt64, T::Type, val)
    if !haskey(ecs.components, key)
        ecs.components[key] = ComponentVector{T}()
    end
    push!(ecs.components[key].IDs, ID)
    push!(ecs.components[key].components, val)
end
function Base.push!(ecs::Registry, key::Symbol, ID::UInt64, val::T) where T 
    push!(ecs, key, ID, T, val)
end



################################################################################
### Entity
################################################################################

# Entity:
# - A collection of components
# - maybe change components in entities to pointers/refs?



struct Entity
    ID::UInt64
    ecs::Registry
    components::Vector{Symbol}
end

function Entity(ecs::Registry)
    ID = ecs.max_ID[]
    ecs.max_ID[] += 1
    e = Entity(ID, ecs, Vector{Symbol}())
    push!(entities, e)
    e
end

# Do I want this? I assume this kinda sucks for performance?
# @inline function Base.getproperty(e::Entity, key::Symbol)
#     if key in (:name, :ID, :ecs)
#         getfield(e, key)
#     elseif haskey(e.components, key)
#         component(e.ecs, key, e.ID)
#     end
# end


function Base.push!(e::Entity, key::Symbol, component)
    push!(e.ecs, key, e.ID, component)
end

Base.getindex(e::Entity, key::Symbol) = component(e.ecs, key, e.ID)
Base.keys(e::Entity) = e.components
Base.haskey(e::Entity, key::Symbol) = key in e.components


# maybe add EntityData thingy, which collects components?



################################################################################
### Grouping
################################################################################

# this looks like a bad :(


struct GroupIterator{T <: Tuple}
    components::T
end

function group(ecs::Registry, keys::Symbol...)
    if length(keys) == 1
        return ecs[keys[1]]
    end
    GroupIterator(tuple((ecs[key] for key in keys)...))
end

function iterate(g::GroupIterator)
    iterate(g, tuple((0 for _ in eachindex(g.components))))
end

function iterate(g::GroupIterator, state)
    idx = state[1]+1
    target_ID = g.components[1].IDs[idx]
    
    not_found = true
    state = state .+ 1
    if any(length(g.components[group].IDs) > state[group] for group in eachindex(state))
        return nothing
    end

    while not_found
        for group in eachindex(state)
            idx = state[group]
            components = g.components[group]

            if components.IDs[idx] == target_ID
                # target at next index
                continue
            elseif components.IDs[idx] > target_ID
                # target doesn't exist (next index already larger)
                target_ID = components.IDs[idx]
                break
            else
                # Search, try next 10 values first
                l = idx
                N = length(components.IDs)
                r = min(idx+10, N)
                @label repeat_label
                if components.IDs[r] > target_ID
                    # target in range, do linear search
                    i = findfirst(ID -> ID ≥ target_ID, components.IDs[l:r])
                    state = tuple(state[1:group-1]..., i, state[group+1:end]...)
                    if components.IDs[i] == target_ID
                        # target found
                        continue
                    else
                        # target doesn't exist, make next larger new target
                        target_ID = components.IDs[i]
                    end
                elseif r == N
                    # Out of bounds
                    return nothing
                else
                    # Bisection search
                    l = r
                    r = N
                    while r-l > 10
                        m = div(r+l, 2)
                        if components.IDs[m] > target_ID
                            r = m
                        else
                            l = m
                        end
                    end
                    # do linear search
                    @goto repeat_label
                end

            end
        end
    end

    return (
        tuple((g.components[group].components[state[group]] for group in eachindex(state))...),
        state
    )
end
    



################################################################################
# Usuage of EnTT:
# mild translation
# TODO remove

struct MeshComponent end
struct TransformComponent end

registry = Registry()
# entity = create(registry)
entity = Entity(registry)
# push!(entity, TransformComponent, TransformComponent())
push!(entity, :transform, TransformComponent())

# if has(entity, TransformComponent)
if haskey(entity, :transform)
    # transform = get(entity, TransformComponent)
    transform = entity[:transform]
end

# view = view(registry, TransformComponent)
# for entity in view
    # transform = get(view, entity, TransformComponent)
for transform in registry[:transform]
    ...
end

# TODO !!! This would not work !!!
# Need to filter components of the same entity?
# # group = group(registry, TransformComponent, MeshComponent)
# # for entity in group
# #     transform, mesh = get(entity, TransformComponent, MeshComponent)
# for (transform, mesh) in zip(registry[:transform], registry[:mesh])
#     submit(mesh, transform)
# end
for (transform, mesh) in group(registry, :transform, :mesh)
    submit(mesh, transform)
end