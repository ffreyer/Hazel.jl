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
    view = rotationmatrix_z(-rotation) * translationmatrix(position)
    projection_view = projection * view
    OrthographicCamera(position, rotation, projection, view, projection_view)
end

function recalculate!(cam::OrthographicCamera)
    cam.projection_view = cam.projection * cam.view
end
function recalculate_view!(cam::OrthographicCamera)
    cam.view =
        rotationmatrix_z(-cam.rotation) *
        translationmatrix(cam.position)
    recalculate!(cam)
end

# Get and set:
"""
    moveto!(camera, position)

Moves the camera to a given position
"""
function moveto!(cam::OrthographicCamera{T}, pos::Point3) where {T}
    moveto!(cam, Vec{3, T}(pos))
end
moveto!(cam::OrthographicCamera{T}, pos::Vec3) where {T} = moveto!(cam, Vec{3, T}(pos))
function moveto!(cam::OrthographicCamera{T}, pos::Vec3{T}) where {T}
    cam.position = pos
    recalculate_view!(cam)
    pos
end

"""
    moveby!(camera, offset)

Moves the camera by a given offset
"""
function moveby!(cam::OrthographicCamera{T}, offset::Point3) where {T}
    moveby!(cam, Vec{3, T}(offset))
end
moveby!(cam::OrthographicCamera{T}, offset::Vec3) where {T} = moveby!(cam, Vec{3, T}(offset))
function moveby!(cam::OrthographicCamera{T}, offset::Vec3{T}) where {T}
    cam.position = cam.position + offset
    recalculate_view!(cam)
    cam.position
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
rotateto!(cam::OrthographicCamera{T}, angle) where {T} = rotateto!(cam, T(angle))
function rotateto!(cam::OrthographicCamera{T}, angle::T) where {T}
    cam.rotation = angle
    recalculate_view!(cam)
    angle
end
"""
    rotateby!(camera, angle)

Rotates the camera by a given angle.
"""
rotateby!(cam::OrthographicCamera{T}, angle) where {T} = rotateby!(cam, T(angle))
function rotateby!(cam::OrthographicCamera{T}, angle::T) where {T}
    cam.rotation += angle
    recalculate_view!(cam)
    cam.rotation
end
"""
    rotation(camera)

Returns the current rotation fo the camera
"""
rotation(cam::OrthographicCamera) = cam.rotation

projection(cam::OrthographicCamera) = cam.projection
view(cam::OrthographicCamera) = cam.view
projection_view(cam::OrthographicCamera) = cam.projection_view
