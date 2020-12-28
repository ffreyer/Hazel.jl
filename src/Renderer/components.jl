# This file is for the more generic components. Components that are specialized
# to a certain system will most likely not be here.


# Name
# SimpleTexture
# ColorComponent
# Transform
# IsVisible
# TilingFactor
# ScriptComponent



@doc """
    NameComponent([name = "Unnamed Entity"])

This component holds a name.
""" NameComponent
@component struct NameComponent
    name::String
end
NameComponent() = NameComponent("Unnamed Entity")
Base.string(c::NameComponent) = c.name



@doc """
    SimpleTexture([texture = blank_texture()])

This component holds a texture. It can be created with a `Texture2D` or 
`SubTexture`, though it does not hold uv information to correctly use the 
latter.
""" SimpleTexture
@component struct SimpleTexture
    texture::Texture2D
end
SimpleTexture() = blank_texture()
SimpleTexture(tex::SubTexture) = SimpleTexture(tex.texture)
destroy(t::SimpleTexture) = destroy(t.texture)



@doc """
    ColorComponent([color = Vec4f0(1)])

Holds a color.
""" ColorComponent
@component struct ColorComponent
    color::Vec4f0
end
ColorComponent() = Vec4f0(1)



@doc """
    Transform([translation = Vec3f0(0), rotation = Vec3f0(0), scale = Vec3f0(1)])

Holds a `translation`, `rotation` and `scale` vector and the derived 
transformation matrix `transform`. Also hold a Bool `has_changed` to allow
reactions in Systems. (i.e. Batch rendering, Camera)
""" Transform
@component mutable struct Transform
    translation::Vec3f0
    rotation::Vec3f0
    scale::Vec3f0
    transform::Mat4f0
    has_changed::Bool
end
function transform(translation::Vec3f0, rotation::Vec3f0, scale::Vec3f0)
    translationmatrix(translation) *
    rotationmatrix_x(rotation[1]) *
    rotationmatrix_y(rotation[2]) *
    rotationmatrix_z(rotation[3]) *
    scalematrix(scale)
end
function Transform(
        translation = Vec3f0(0), rotation = Vec3f0(0), scale = Vec3f0(1), 
        has_changed = true
    )
    Transform(
        translation, rotation, scale, 
        transform(translation, rotation, scale), 
        has_changed
    )
end
function Base.setproperty!(t::Transform, field::Symbol, value)
    setfield!(t, field, value)
    if field in (:translation, :rotation, :scale)
        setfield!(t, :transform, transform(t.translation, t.rotation, t.scale))
        setfield!(t, :has_changed, true)
    end
    value
end



@doc """
    IsVisible([val = true])

Holds a Bool to indicate whether the object should be drawn.
""" IsVisible
@component struct IsVisible
    val::Bool
end
IsVisible() = IsVisible(true)



@doc """
    TilingFactor([tf = 1f0])

Holds a tiling factor which is multiplied to the uv coordinates. Semi-internal
for batch rendered quads. (?)
""" TilingFactor
@component struct TilingFactor
    tf::Float32
end
TilingFactor() = TilingFactor(1f0)



@doc """
    ScriptComponent([; create!, update!, destroy!])

Creates a script component.

* `create!(entity)`: TODO
* `update!(app, entity, dt)`: runs once per update
* `destroy!(entity)`: TODO
""" ScriptComponent
@component mutable struct ScriptComponent
    create!::Function
    update!::Function
    destroy!::Function
end
function ScriptComponent(;
        create! = (entity) -> nothing,
        update! = (app, raw_entity, dt) -> nothing,
        destroy! = (script_component) -> nothing
    )
    # Still need to debate how exactly this should work
    # Pretty sure I don't want Functors here, because
    #   - the component array would be unstable
    #   - the component array would have var-sized elements
    #   - We could just have extra components carrying that data
    # Also no abstract type for similar reasons
    # destroy! could be called on destroy!(scene) or as a finalizer
    # create! should be on push!, probably
    # Kinda need an app reference too though, ugh
    finalizer(destroy, ScriptComponent(create!, update!, destroy!))
end
destroy(s::ScriptComponent) = s.destroy!(s)
function Base.push!(e::AbstractEntity, script::ScriptComponent)
    script.create!(Entity(registry(e), RawEntity(e)))
    registry(e)[RawEntity(e)] = script
end