"""
    RenderObject(shader, vertex_array)
"""
struct RenderObject{S, VA}
    shader::S
    vertex_array::VA
end

abstract type AbstractScene end
struct Scene{
        CT <: AbstractCamera
    } <: AbstractScene
    camera::CT
    render_objects::Vector{RenderObject}
end
"""
    Scene(camera[, render_objects])
"""
Scene(camera::AbstractCamera) = Scene(camera, RenderObject[])
Base.push!(scene::Scene, robj::RenderObject) = push!(scene.render_objects, robj)

camera(scene::Scene) = scene.camera


# TODO
# figure out what this should really be
# implement
#   - deleteat!, pop!
#   - iteration
#   - length, size
#   - maybe draw_indexed?
