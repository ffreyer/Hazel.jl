mutable struct OrthographicCamera <: AbstractCamera
    projection::Mat4f0
    view::Mat4f0
    projection_view::Mat4f0
end

"""
    OrthographicCamera(left, right, bottom, top[, near, far])

Creates an orthographic camera.
"""
@HZ_profile function OrthographicCamera(
        left, right, bottom, top, znear=-10_000, zfar=10_000
    )

    projection = orthographicprojection(left, right, bottom, top, znear, zfar)
    view = rotationmatrix_z(Float32(0)) * translationmatrix(Vec3f0(0))
    projection_view = projection * view
    OrthographicCamera(Mat4f0(projection), Mat4f0(view), Mat4f0(projection_view))
end

@HZ_profile function recalculate!(cam::OrthographicCamera)
    cam.projection_view = cam.projection * cam.view
end
@HZ_profile function recalculate_view!(
        cam::OrthographicCamera, position::Vec3f0, rotation
    )
    cam.view =
        rotationmatrix_z(-rotation) *
        translationmatrix(position)
    recalculate!(cam)
end

function projection!(
        c::OrthographicCamera,
        left, right, bottom, top, znear=-10_000, zfar=10_000
    )
    c.projection = orthographicprojection(left, right, bottom, top, znear, zfar)
    recalculate!(c)
end

projection(cam::OrthographicCamera) = cam.projection
view(cam::OrthographicCamera) = cam.view
projection_view(cam::OrthographicCamera) = cam.projection_view

function orthographicprojection(left, right, bottom, top, znear, zfar)
    orthographicprojection(
        Float32(left), Float32(right), 
        Float32(bottom), Float32(top), 
        Float32(znear), Float32(zfar)
    ) 
end