################################################################################
### Components
################################################################################


# Transform2D takes the role of the view matrix

# Merge these into one, so we can switch between ortho and perspective easily

@enum ProjectionType Orthographic=1 Perspective=2

@component mutable struct CameraComponent
    # Orthographic
    aspect::Float32
    height::Float32
    o_near::Float32
    o_far::Float32

    # Perspective
    fov::Float32
    p_near::Float32
    p_far::Float32
    
    projection_type::ProjectionType
    has_changed::Bool # maybe unneeded?
    fix_aspect_ratio::Bool
    active::Bool
    
    projection::Mat4f0
    projection_view::Mat4f0
end

function CameraComponent(;
        aspect = 16f0/9f0, height = 10f0, o_near = -1f0, o_far = 1f0,
        fov = 45, p_near = 1f-2, p_far = 1f4,
        projection_type = Orthographic, fix_aspect_ratio = false, active = true, 
        has_changed = false,
        projection = if projection_type === Orthographic
            orthographicprojection(aspect, height, o_near, o_far)
        else
            perspectiveprojection(cc.fov, aspect, p_near, p_far)
        end,
        projection_view = Mat4f0(I)
    )
    CameraComponent(
        aspect, height, o_near, o_far,
        fov, p_near, p_far, 
        projection_type, has_changed, fix_aspect_ratio, active,
        projection, projection_view
    )
end

# Maybe?
function Base.setproperty!(cc::CameraComponent, field::Symbol, value)
    if field in (:aspect, :height, :o_near, :o_far, :p_near, :p_far, :fov, :projection_type)
        setfield!(cc, :has_changed, true)
        projection!(cc)
    end
    setfield!(cc, field, value)    
end

function projection!(cc::CameraComponent)
    cc.projection = if cc.projection_type === Orthographic
        left    = -0.5 * cc.aspect * cc.height
        right   = +0.5 * cc.aspect * cc.height
        bottom  = -0.5 * cc.height
        top     = +0.5 * cc.height
        orthographicprojection(left, right, bottom, top, cc.o_near, cc.o_far)
    else
        perspectiveprojection(cc.fov, cc.aspect, cc.p_near, cc.p_far)
    end
    nothing
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
        orthographic_near = -1f0, orthographic_far = 1f0,
        fov = 45, perspective_near = 0f0, perspective_far = 1f4,
        fix_aspect_ratio = false, active = true
    )
    we = Entity(
        scene, 
        NameComponent(name), 
        Transform2D(position, rotation, scale),
        CameraComponent(
            aspect = aspect, height = height, 
            o_near = orthographic_near, o_far = orthographic_far, 
            fov = fov, p_near = perspective_near, p_far = perspective_far,
            fix_aspect_ratio = fix_aspect_ratio, active = active
        ),
        components...
    )
    cam = Camera(we)
    recalculate_projection_view!(cam)
    cam
end


# Backend


function recalculate_projection_view!(cam::Camera)
    cam[CameraComponent].projection_view = 
        cam[Transform2D].T * cam[CameraComponent].projection
    nothing
end


# Frontend


function activate!(c::AbstractEntity)
    cameras = registry(c)[CameraComponent]
    for e in @entities_in(cameras)
        should_be_active = e == RawEntity(c)
        if cameras[e].active != should_be_active
            cameras[e].active = should_be_active
        end
    end
    nothing
end

function orthographic!(cam::Camera)
    cc = cam[CameraComponent]
    cc.projection_type = Orthographic
    projection!(cc)
    recalculate_projection_view!(cam)
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

requested_components(::CameraUpdate) = (Transform2D, CameraComponent)
function update!(app, ::CameraUpdate, reg::AbstractLedger, ts)
    transforms = reg[Transform2D]
    cameras = reg[CameraComponent]

    for e in @entities_in(transforms && cameras)
        if cameras[e].active
            T = transforms[e]
            C = cameras[e]
            if T.has_changed || C.has_changed
                C.projection_view = T.T * C.projection
                transforms[e] = Transform2D(T, has_changed=false)
                C.has_changed = false
            end
        end
    end
    nothing
end