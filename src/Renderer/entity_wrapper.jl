"""
    WrappedEntity(scene, entity)
    WrappedEntity(scene, components...)

Wraps an entity to make it more convenient to use. Essentially on can modify
components directly with a `WrappedEntity`, rather than going through the
registry/ledger (or here Scene).

WrappedEntity should generally be returned by game object constructors.
"""
struct WrappedEntity
    parent::Scene
    entity::Entity
end

function WrappedEntity(scene::Scene, components...)
    WrappedEntity(scene, Entity(registry(scene), components...))
end

registry(we::WrappedEntity) = registry(we.parent)
entity(we::WrappedEntity) = we.entity
Base.push!(we::WrappedEntity, component) = registry(we)[we.entity] = component
Base.haskey(we::WrappedEntity, key) = we.entity in registry(we)[key]
Base.in(key, we::WrappedEntity) = we.entity in registry(we)[key]
Base.getindex(we::WrappedEntity, key) = registry(we)[key][we.entity]
Base.setindex!(we::WrappedEntity, val, key) = registry(we)[key][we.entity] = val
Base.delete!(we::WrappedEntity) = delete!(registry(we), we.entity)
Base.delete!(we::WrappedEntity, key) = pop!(registry(we)[key], we.entity)
Base.pop!(we::WrappedEntity, key) = pop!(registry(we)[key], we.entity)


# """
#     @implement_entity_wrapper_methods Type.field

# Implements WrappedEntity methods for the given `Type` with `Type.field` being a
# WrappedEntity.
# """
# macro implement_entity_wrapper_methods(input::Expr)
function implement_entity_wrapper_methods(T, field)
    quote
        registry(x::$T) = registry(x.$field)
        Base.push!(x::$T, component) = push!(x.$field, component)
        Base.haskey(x::$T, key) = haskey(x.$field, key)
        Base.in(key, x::$T) = in(key, x.$field)
        Base.getindex(x::$T, key) = getindex(x.$field, key)
        Base.setindex!(x::$T, val, key) = setindex!(x.$field, val, key)
        Base.delete!(x::$T) = delete!(x.$field)
        Base.delete!(x::$T, key) = delete!!(x.$field, key)
        Base.pop!(x::$T, key) = pop!(x.$field, key)
        entity(x::$T) = entity(x.$field)
    end
end
