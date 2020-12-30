# alt MM - pan
# alt left - rotate
# alt right - zoom

mutable struct EditorCamera
    # settings
    fov::Float32
    aspect::Float32
    near::Float32
    far::Float32
    viewport::Vec2f0
    
    # state
    position::Vec3f0
    focal_point::Vec3f0
    has_changed::Bool
    last_mouse_pos::Vec2f0

    distance::Float32
    pitch::Degree
    yaw::Degree

    # Matrices
    view::Mat4f0
    projection::Mat4f0
    projection_view::Mat4f0
end

function EditorCamera(;
        fov = 45f0, near = 0.1f0, far = 1f3,
        viewport = Vec2f0(1280, 720),
        aspect = viewport[1] / viewport[2],
        focal_point = Vec3f0(0),
        initial_mouse_position = Vec2f0(0, 0),
        distance = 10f0, pitch = 0°, yaw = 0°
    )

    position = focal_point .- Quaternion(yaw, pitch) * Vec3f0(0, 0, -1) * distance
    view = inv(translationmatrix(position) * rotation_matrix(yaw, pitch))
    projection = perspectiveprojection(fov, aspect, near, far)
    projection_view = projection * view

    EditorCamera(
        fov, aspect, near, far, viewport,
        position, focal_point, false, initial_mouse_position,
        distance, pitch, yaw, 
        view, projection, projection_view
    )
end


# function Base.setproperty!(cam::EditorCamera, field::Symbol, value)
#     setfield!(cam, field, value)
#     if field == :viewport
#         setfield!(cam, :aspect, viewport[1] / viewport[2])
#         update_projection!(cam)
#     elseif field in (:fov, :aspect, :near, :far)
#         update_projection!(cam)
#     end
#     cam
# end

function resize_viewport!(cam::EditorCamera, w, h)
    cam.viewport = Vec2f0(w, h)
    cam.aspect = Float32(w/h)
    update_projection!(cam)
end

function update_position!(cam::EditorCamera)
    cam.position = cam.focal_point .- forward(cam) * cam.distance
    cam
end
function update_view!(cam::EditorCamera)
    cam.view = inv(translationmatrix(cam.position) * rotation_matrix(cam))
    update_projection_view!(cam)
end
function update_projection!(cam::EditorCamera)
    cam.projection = perspectiveprojection(cam.fov, cam.aspect, cam.near, cam.far)
    update_projection_view!(cam)
end
function update_projection_view!(cam::EditorCamera)
    cam.projection_view = cam.projection * cam.view
    cam
end



function pan_speed(cam::EditorCamera)
    s = min.(cam.viewport / 1000f0, 2.4f0)
    0.0366f0 .* s .* s .- 0.1778f0 * s .+ 0.3021f0
end

rotation_speed(cam::EditorCamera) = 45.8366f0

function zoom_speed(cam::EditorCamera)
    distance = max(cam.distance * 0.2f0, 0f0)
    min(distance * distance, 100f0)
end



Quaternion(cam::EditorCamera) = Quaternion(cam.yaw, cam.pitch)
Quaternion(yaw, pitch) = Quaternion(radians(yaw), radians(pitch))
function Quaternion(yaw::AbstractFloat, pitch::AbstractFloat)
    cy = cos(-yaw * 0.5)
    sy = sin(-yaw * 0.5)
    cp = cos(-pitch * 0.5)
    sp = sin(-pitch * 0.5)

    Quaternion(cp * cy , -sp * sy, sp * cy, cp * sy)
end

right(cam::EditorCamera) = Quaternion(cam) * Vec3f0(1, 0, 0)
up(cam::EditorCamera) = Quaternion(cam) * Vec3f0(0, 1, 0)
forward(cam::EditorCamera) = Quaternion(cam) * Vec3f0(0, 0, -1)

rotation_matrix(cam::EditorCamera) = rotationmatrix4(Quaternion(cam.yaw, cam.pitch))
rotation_matrix(yaw, pitch) = rotationmatrix4(Quaternion(yaw, pitch))



function update!(app, cam::EditorCamera, ts)
    if keypressed(app, KEY_LEFT_ALT)
        mouse = mouse_pos(app)
        delta = (mouse .- cam.last_mouse_pos) .* 0.003f0
        cam.last_mouse_pos = mouse

        need_update = false
        if mousebutton_pressed(app, MOUSE_BUTTON_MIDDLE)
            mouse_pan!(cam, delta)
            need_update = true
        elseif mousebutton_pressed(app, MOUSE_BUTTON_LEFT)
            mouse_rotate!(cam, delta)
            need_update = true
        elseif mousebutton_pressed(app, MOUSE_BUTTON_RIGHT)
            mouse_zoom!(cam, delta[2])
            need_update = true
        end

        need_update && update_view!(cam)
    end
    nothing
end

function handle!(cam::EditorCamera, event::MouseScrolledEvent)
    mouse_zoom!(cam, event.dy * 0.1f0)
    update_view!(cam)
    false
end



function mouse_pan!(cam::EditorCamera, delta::Vec2f0)
    v = pan_speed(cam)
    cam.focal_point = cam.focal_point .-
        right(cam) * delta[1] * v[1] * cam.distance .+
        up(cam) * delta[2] * v[2] * cam.distance
    update_position!(cam)
    nothing
end

function mouse_rotate!(cam::EditorCamera, delta::Vec2f0)
    pm = up(cam)[2] > 0 ? -1f0 : +1f0
    cam.pitch = cam.pitch + Degree(pm * delta[1] * rotation_speed(cam))
    cam.yaw = cam.yaw + Degree(pm * delta[2] * rotation_speed(cam))
    update_position!(cam)
    nothing
end

function mouse_zoom!(cam::EditorCamera, delta)
    cam.distance = cam.distance - delta * zoom_speed(cam)
    if cam.distance < 1f0
        cam.focal_point = cam.focal_point .+ forward(cam)
        cam.distance = 1f0
    end
    update_position!(cam)
    nothing
end