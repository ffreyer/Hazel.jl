mutable struct OrthographicCamera{T} <: AbstractCamera
    projection::Mat4{T}
    view::Mat4{T}
    projection_view::Mat4{T}
end

"""
    OrthographicCamera(left, right, bottom, top[, near, far])

Creates an orthographic camera.
"""
@HZ_profile function OrthographicCamera(
        left::T, right::T, bottom::T, top::T, znear=T(-10_000), zfar=T(10_000)
    ) where {T}

    projection = orthographicprojection(left, right, bottom, top, znear, zfar)
    view = rotationmatrix_z(T(0)) * translationmatrix(Vec3{T}(0))
    projection_view = projection * view
    OrthographicCamera(projection, view, projection_view)
end

@HZ_profile function recalculate!(cam::OrthographicCamera)
    cam.projection_view = cam.projection * cam.view
end
@HZ_profile function recalculate_view!(
        cam::OrthographicCamera{T}, position::Vec3{T}, rotation::T
    ) where {T}
    cam.view =
        rotationmatrix_z(-rotation) *
        translationmatrix(position)
    recalculate!(cam)
end

function projection!(
        c::OrthographicCamera{T},
        left::T, right::T, bottom::T, top::T, znear=T(-10_000), zfar=T(10_000)
    ) where {T}
    c.projection = orthographicprojection(left, right, bottom, top, znear, zfar)
    recalculate!(c)
end

projection(cam::OrthographicCamera) = cam.projection
view(cam::OrthographicCamera) = cam.view
projection_view(cam::OrthographicCamera) = cam.projection_view
