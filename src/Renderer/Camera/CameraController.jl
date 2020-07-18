abstract type AbstractCameraController end

mutable struct OrthographicCameraController{T} <: AbstractCameraController
    aspect_ratio::T
    camera::OrthographicCamera{T}

    zoom::T
    rotation::T
    position::Vec3{T}

    translation_speed::T
    rotation_speed::T
    zoom_speed::T

    rotation_enabled::Bool
end

@HZ_profile function OrthographicCameraController(aspect_ratio; rotation=false)
    zoom = 1f0
    aspect_ratio = Float32(aspect_ratio)
    cam = OrthographicCamera(
        -aspect_ratio * zoom, aspect_ratio * zoom,
        -zoom, zoom
    )

    OrthographicCameraController(
        aspect_ratio, cam,
        zoom, 0f0, Vec3f0(0),
        1f0, 1f0, 0.25f0,
        rotation
    )
end

# app could also be window
@HZ_profile function update!(c::OrthographicCameraController, app, dt)
    # Move camera
    offset = Vec3f0(
        keypressed(app, KEY_D) - keypressed(app, KEY_A),
        keypressed(app, KEY_W) - keypressed(app, KEY_S),
        0
    )
    Hazel.moveby!(c, dt * c.translation_speed * offset)
    if c.rotation_enabled
        # Rotate camera
        rotation = keypressed(app, KEY_E) - keypressed(app, KEY_Q)
        rotateby!(c, dt * c.rotation_speed * rotation)
    end
end

@HZ_profile function handle!(c::OrthographicCameraController{T}, e::MouseScrolledEvent) where {T}
    c.zoom = max(0.1f0, c.zoom - T(c.zoom_speed * e.dy))
    c.translation_speed = c.zoom
    projection!(
        c.camera,
        -c.aspect_ratio * c.zoom, c.aspect_ratio * c.zoom, -c.zoom, c.zoom
    )
    false
end

@HZ_profile function handle!(c::OrthographicCameraController{T}, e::WindowResizeEvent) where {T}
    c.aspect_ratio = T(e.width / e.height)
    projection!(
        c.camera, -c.aspect_ratio * c.zoom, c.aspect_ratio * c.zoom, -c.zoom, c.zoom
    )
    false
end



"""
    moveto!(camera_controller, position)

Moves the camera to a given position
"""
@HZ_profile function moveto!(c::OrthographicCameraController{T}, pos::Point3) where {T}
    moveto!(c, Vec{3, T}(pos))
end
@HZ_profile function moveto!(c::OrthographicCameraController{T}, pos::Vec3) where {T}
    moveto!(c, Vec{3, T}(pos))
end
@HZ_profile function moveto!(c::OrthographicCameraController{T}, pos::Vec3{T}) where {T}
    c.position = pos
    recalculate_view!(c.camera, c.position, c.rotation)
    pos
end

"""
    moveby!(camera_controller, offset)

Moves the camera by a given offset
"""
@HZ_profile function moveby!(c::OrthographicCameraController{T}, offset::Point3) where {T<:Real}
    moveby!(c, Vec{3, T}(offset))
end
@HZ_profile function moveby!(c::OrthographicCameraController{T}, offset::Vec3) where {T<:Real}
    moveby!(c, Vec{3, T}(offset))
end
@HZ_profile function moveby!(c::OrthographicCameraController{T}, offset::Vec3{T}) where {T<:Real}
    c.position += offset
    recalculate_view!(c.camera, c.position, c.rotation)
    c.position
end

"""
    position(camera_controller)

Returns the current position of the camera.
"""
position(c::OrthographicCameraController) = c.position


"""
    rotateto!(camera_controller, angle)

Rotates the camera to the given angle.
"""
@HZ_profile function rotateto!(c::OrthographicCameraController{T}, angle::T) where {T<:Real}
    c.rotation = angle
    recalculate_view!(c.camera, c.position, c.rotation)
    angle
end
"""
    rotateby!(camera_controller, angle)

Rotates the camera by a given angle.
"""
@HZ_profile function rotateby!(c::OrthographicCameraController{T}, angle::T) where {T<:Real}
    c.rotation += angle
    recalculate_view!(c.camera, c.position, c.rotation)
    c.rotation
end
"""
    rotation(camera_controller)

Returns the current rotation of the camera
"""
rotation(c::OrthographicCameraController) = c.rotation


"""
    zoom!(camera_controller, zoom)

Sets the zoom level of the camera_controller
"""
zoom!(c::OrthographicCameraController{T}, zoom::T) where {T} = c.zoom = zoom
"""
    zoom(camera_controller)

Returns the current zoom level of the camera_controller
"""
zoom(c::OrthographicCameraController) = c.zoom


camera(c::OrthographicCameraController) = c.camera
