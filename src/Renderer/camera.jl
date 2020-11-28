################################################################################
### Component(s)
################################################################################



# NOTE: TheCherno has this split into (projection, active) and (view^-1)
@component struct CameraComponent
    projection::Mat4f0
    view::Mat4f0
    projection_view::Mat4f0

    active::Bool
end
CameraComponent() = CameraComponent(Mat4f0(I), Mat4f0(I), Mat4f0(I), true)
function CameraComponent(projection::Mat4f0, view::Mat4f0, active::Bool) 
    CameraComponent(projection, view, projection*view, active)
end
function CameraComponent(
        c::CameraComponent;
        projection = c.projection, view = c.view, active = c.active
    )
    CameraComponent(projection, view, projection*view, active)
end



################################################################################
### Entity
################################################################################



struct Camera
    we::WrappedEntity
end
@implement_entity_wrapper_methods Camera.we


function Camera(
        scene, components...; 
        name = "Camera", 
        projection = Mat4f0(I), view = Mat4f0(I), active = false
    )
    we = WrappedEntity(
        scene, NameComponent(name), CameraComponent(projection, view, active), 
        components...
    )
    Camera(we)
end



################################################################################
### Utilities
################################################################################



function activate!(c::Camera)
    cameras = c.we.parent[CameraComponent]
    for e in @entities_in(cameras)
        should_be_active = e == c.we.entity
        if cameras[e].active != should_be_active
            cameras[e] = CameraComponent(cameras[e], active = should_be_active)
        end
    end
    nothing
end

# TODO ...