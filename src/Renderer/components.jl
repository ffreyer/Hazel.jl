# This file is for the more generic components. Components that are specialized
# to a certain system will most likely not be here.


# Name
# SimpleTexture
# ColorComponent
# Transform2D (semi-internal)
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
    Transform2D([position = Vec3f0(0), rotation = 0f0, scale = Vec2f0(1)])
    Transform2D(transform2D[; position, rotation, scale])

Semi-internal for batch rendered quads. Holds a `position`, `rotation`, `scale` 
and the derived transformation matrix `T`.
""" Transform2D
@component struct Transform2D
    position::Vec3f0
    rotation::Float32
    scale::Vec2f0
    T::Mat4f0
    has_changed::Bool
end
function Transform2D(position = Vec3f0(0), rotation = 0f0, scale = Vec2f0(1))
    T = translationmatrix(position) * rotationmatrix_z(rotation) * 
        scalematrix(Vec3f0(scale[1], scale[2], 1))
    Transform2D(
        _pad(Vec3f0, position, 0), 
        Float32(rotation), 
        _pad(Vec3f0, scale, 1.0), T, true
    )
end
# convenience
function Transform2D(
        t::Transform2D; 
        position=t.position, rotation=t.rotation, scale=t.scale, has_changed=true
    )
    T = translationmatrix(position) * rotationmatrix_z(rotation) * 
        scalematrix(Vec3f0(scale[1], scale[2], 1))
    Transform2D(position, rotation, scale, T, has_changed)
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

* `create!(app, entity)`: TODO
* `update!(app, entity, dt)`: runs once per update
* `destroy!(app, entity)`: TODO
""" ScriptComponent
@component struct ScriptComponent
    create!::Function
    update!::Function
    destroy!::Function
end
function ScriptComponent(;
        create! = (app, entity) -> nothing,
        update! = (app, entity, dt) -> nothing,
        destroy! = (app, entity) -> nothing
    )
    ScriptComponent(create!, update!, destroy!)
end