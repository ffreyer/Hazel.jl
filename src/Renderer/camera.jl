################################################################################
### Component(s)
################################################################################



# NOTE: TheCherno has this split into (projection, active) and (view^-1)
@component mutable struct CameraComponent
    projection::Mat4f0
    view::Mat4f0
    projection_view::Mat4f0

    ortho_size::Float32
    ortho_near::Float32
    ortho_far::Float32
    aspect::Float32

    fix_aspect_ratio::Bool
    active::Bool
end
function CameraComponent(;
        projection = Mat4f0(I), view = Mat4f0(I), 
        projection_view = projection * view,
        ortho_size = 10f0, ortho_near = -1f0, ortho_far = 1f0, aspect = 16f0/9f0,
        fix_aspect_ratio = false, active = true
    )
    CameraComponent(
        projection, view, projection_view, 
        ortho_size, ortho_near, ortho_far, aspect,
        fix_aspect_ratio, active
    )
end



function recalculate!(c::CameraComponent)
    aspect = c.aspect
    left    = -0.5aspect * c.ortho_size
    right   = +0.5aspect * c.ortho_size
    bottom  = -0.5 * c.ortho_size
    top     = +0.5 * c.ortho_size

    c.projection = orthographicprojection(
        left, right, bottom, top, c.ortho_near, c.ortho_far
    )
    recalculate_projection_view!(c)
    nothing
end

function recalculate_projection_view!(c::CameraComponent)
    c.projection_view = c.view * c.projection
    nothing
end

function orthographic!(
        c::CameraComponent, 
        size=c.ortho_size, near_clip=c.ortho_near, far_clip=c.ortho_far
    )
    c.ortho_size = Float32(size)
    c.ortho_near = Float32(near_clip)
    c.ortho_far  = Float32(far_clip)
    recalculate!(c)
    nothing
end

function resize_viewport!(c::CameraComponent, width, height)
    c.aspect = width / height
    recalculate!(c)
    nothing
end



################################################################################
### Entity
################################################################################



struct Camera
    we::WrappedEntity
end
# @implement_entity_wrapper_methods Camera.we
eval(implement_entity_wrapper_methods(Camera, :we))


function Camera(scene, components...; name = "Camera", kwargs...)
    we = WrappedEntity(
        scene, NameComponent(name), 
        CameraComponent(; kwargs...), 
        components...
    )
    Camera(we)
end



################################################################################
### Utilities
################################################################################



function activate!(c::Camera)
    cameras = registry(c)[CameraComponent]
    for e in @entities_in(cameras)
        should_be_active = e == entity(c)
        if cameras[e].active != should_be_active
            cameras[e].active = should_be_active
        end
    end
    nothing
end

function orthographic!(c::Camera, size=10f0, near_clip=-1f0, far_clip=1f0)
    orthographic!(c[CameraComponent], size, near_clip, far_clip)
end

function resize_viewport!(c::Camera, width, height)
    resize_viewport!(c[CameraComponent], width, height)
end

# TODO ...