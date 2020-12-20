const RawEntity = Overseer.Entity

abstract type AbstractEntity end

"""
    abstract type WrappedEntity <: AbstractEntity

A type inheriting from `WrappedEntity` should have a field `entity` of type
`Entity` or `SceneEntity`, or implement

    entity(::ConcreteWrappedEntity) -> Entity or SceneEntity

to implement entity functionality.
"""
abstract type WrappedEntity <: AbstractEntity end

struct Entity <: AbstractEntity
    registry::Overseer.Ledger
    entity::RawEntity
end



"""
    Entity(reg::Overseer.Ledger, entity::Overseer.Entity)
    Entity(reg::Overseer.Ledger, entity::RawEntity)
    Entity(reg::Overseer.Ledger, components...)

    Entity(scene::Scene, entity::Overseer.Entity)
    Entity(scene::Scene, entity::RawEntity)
    Entity(scene::Scene, components...)

Creates an `Entity` which wraps the registry/ledger to simplify modification.
For example, it simplifies `registry(scene)[Component][entity]` to 
`entity[Component]`.

If a set of components is passed instead of a raw entity, a new entity will be 
created and embeded in the passed registry/ledger or scene.
"""
function Entity(reg::Overseer.Ledger, components...)
    Entity(reg, RawEntity(registry(scene), components...))
end



# generic interface
@inline registry(e::AbstractEntity) = e.registry
@inline RawEntity(e::AbstractEntity) = e.entity
Base.push!(e::AbstractEntity, component) = registry(e)[RawEntity(e)] = component
Base.haskey(e::AbstractEntity, key) = RawEntity(e) in registry(e)[key]
Base.in(key, e::AbstractEntity) = RawEntity(e) in registry(e)[key]
Base.getindex(e::AbstractEntity, key) = registry(e)[key][RawEntity(e)]
Base.setindex!(e::AbstractEntity, val, key) = registry(e)[key][RawEntity(e)] = val
Base.delete!(e::AbstractEntity) = delete!(registry(e), RawEntity(e))
Base.delete!(e::AbstractEntity, key) = pop!(registry(e)[key], RawEntity(e))
Base.pop!(e::AbstractEntity, key) = pop!(registry(e)[key], RawEntity(e))
Base.:(==)(e1::AbstractEntity, e2::AbstractEntity) = RawEntity(e1) == RawEntity(e2)


# Overloads
@inline entity(e::WrappedEntity) = e.entity
@inline registry(e::WrappedEntity) = registry(entity(e))
@inline RawEntity(e::WrappedEntity) = RawEntity(entity(e))