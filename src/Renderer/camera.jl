################################################################################
### Components
################################################################################


# Transform2D takes the role of the view matrix

# This is the projection matrix
@component struct OrthographicProjection
    aspect::Float32
    height::Float32
    near::Float32
    far::Float32

    projection::Mat4f0
    has_changed::Bool # maybe unneeded?

    function OrthographicProjection(
            aspect = 16f0/9f0, height = 10f0,
            near = -1f0, far = 1f0,
            projection = orthographicprojection(aspect, height, near, far),
            has_changed = false
        )
        new(aspect, height, near, far, projection, has_changed)
    end
end

function OrthographicProjection(
        p::OrthographicProjection;
        aspect = p.aspect, height = p.height,
        near = p.near, far = p.far,
        projection = orthographicprojection(aspect, height, near, far),
        has_changed = true
    )
    OrthographicProjection(aspect, height, near, far, projection, has_changed)
end

function orthographicprojection(
        aspect::Float32, height::Float32, near::Float32, far::Float32
    )
    left    = -0.5aspect * height
    right   = +0.5aspect * height
    bottom  = -0.5height
    top     = +0.5height
    orthographicprojection(left, right, bottom, top, near, far)
end

# This is extra information
@component mutable struct CameraComponent
    projection_view::Mat4f0
    fix_aspect_ratio::Bool
    active::Bool

    function CameraComponent(
            fix_aspect_ratio=false, active=true, projection_view = Mat4f0(I)
        )
        new(projection_view, fix_aspect_ratio, active)
    end
end



################################################################################
### Entity
################################################################################



struct Camera <: WrappedEntity
    entity::Entity
end


function Camera(
        scene, components...; 
        name = "Unnamed Camera",
        position = Vec3f0(0), rotation = 0f0, scale = Vec2f0(1),
        height = 10f0, width = height * 16f0/9f0, aspect = width/height,
        near = -1f0, far = 1f0,
        fix_aspect_ratio = false, active = true
    )
    we = Entity(
        scene, 
        NameComponent(name), 
        Transform2D(position, rotation, scale),
        OrthographicProjection(aspect, height, near, far),
        CameraComponent(fix_aspect_ratio, active),
        components...
    )
    cam = Camera(we)
    recalculate_projection_view!(cam)
    cam
end


# Backend


function recalculate_projection_view!(cam::Camera)
    cam[CameraComponent].projection_view = 
        cam[Transform2D].T * cam[OrthographicProjection].projection
    nothing
end


# Frontend


function activate!(c::Camera)
    cameras = registry(c)[CameraComponent]
    for e in @entities_in(cameras)
        should_be_active = e == RawEntity(c)
        if cameras[e].active != should_be_active
            cameras[e].active = should_be_active
        end
    end
    nothing
end

function orthographic!(c::Camera; kwargs...)
    c[OrthographicProjection] = OrthographicProjection(
        c[OrthographicProjection]; kwargs...
    )
    recalculate_projection_view!(c)
end


# Transformations

function transform!(c::Camera; kwargs...)
    # We do not want to trigger an update during System
    c[Transform2D] = Transform2D(c[Transform2D]; kwargs..., has_changed=false)
    recalculate_projection_view!(c)
    nothing
end

moveto!(c::Camera, pos::Vec3f0) = transform!(c, position = pos)
rotateto!(c::Camera, θ::Float32) = transform!(c, position = θ)
scaleto!(c::Camera, scale::Vec2f0) = transform!(c, position = scale)

position(c::Camera) = c[Transform2D].position
rotation(c::Camera) = c[Transform2D].rotation
scale(c::Camera) = c[Transform2D].scale

moveby!(c::Camera, v::Vec3f0) = transform!(c, position = position(c) .+ v)
rotateby!(c::Camera, θ::Float32) = transform!(c, rotation = rotation(c) + θ)
scaleby!(c::Camera, s::Vec2f0) = transform!(c, scale = scale(c) .+ s)



################################################################################
### Systems
################################################################################


struct CameraUpdate <: System end

requested_components(::CameraUpdate) = (Transform2D, OrthographicProjection, CameraComponent)
function update!(app, ::CameraUpdate, reg::AbstractLedger, ts)
    transforms = reg[Transform2D]
    projections = reg[OrthographicProjection]
    cameras = reg[CameraComponent]

    for e in @entities_in(transforms && projections && cameras)
        if cameras[e].active
            T = transforms[e]
            P = projections[e]
            if T.has_changed || P.has_changed
                cameras[e].projection_view = T.T * P.projection
                transforms[e] = Transform2D(T, has_changed=false)
                projections[e] = OrthographicProjection(P, has_changed=false)
            end
        end
    end
    nothing
end