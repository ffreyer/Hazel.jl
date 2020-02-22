mutable struct OrthographicCamera{T} <: AbstractCamera
    position::Vec3{T}
    rotation::T
    projection::Mat4{T}
    view::Mat4{T}
    projection_view::Mat4{T}
end

"""
    OrthographicCamera(left, right, bottom, top[, near, far])

Creates an orthographic camera.
"""
function OrthographicCamera(
        left::T, right::T, bottom::T, top::T, znear=T(-1), zfar=T(1)
    ) where {T}

    position = Vec3{T}(0)
    rotation = T(0)
    projection = orthographicprojection(left, right, bottom, top, znear, zfar)
    view = rotationmatrix_z(-rotation) * translationmatrix(-position)
    projection_view = projection * view
    OrthographicCamera(position, rotation, projection, view, projection_view)
end

function recalculate!(cam::OrthographicCamera)
    cam.projection_view = cam.projection * cam.view
end
function recalculate_view!(cam::OrthographicCamera)
    cam.view =
        rotationmatrix_z(-cam.rotation) *
        translationmatrix(-cam.position)
    recalculate!(cam)
end

# Get and set:
"""
    moveto!(camera, position)

Moves the cemra to a given position
"""
function moveto!(cam::OrthographicCamera{T}, pos::Point3{T}) where {T}
    moveto!(cam, Vec{3, T}(pos))
end
function moveto!(cam::OrthographicCamera{T}, pos::Vec3{T}) where {T}
    cam.position = pos
    recalculate_view!(cam)
    pos
end

"""
    position(camera)

Returns the current position of the camera.
"""
position(cam::OrthographicCamera) = cam.position


"""
    rotateto!(camera, angle)

Rotates the camera to the given angle.
"""
function rotateto!(cam::OrthographicCamera{T}, angle::T) where {T}
    cam.rotation = angle
    recalculate_view!(cam)
    angle
end
"""
    rotation(camera)

Returns the current rotation fo the camera
"""
rotation(cam::OrthographicCamera) = cam.rotation

projection(cam::OrthographicCamera) = cam.projection
view(cam::OrthographicCamera) = cam.view
projection_view(cam::OrthographicCamera) = cam.projection_view
