"""
    RenderObject(shader, vertex_array)

Creates a new RenderObject that can be pushed to the scene.

Calls `unbind(vertex_array)` to avoid accidental overwriting. You may bind it
again by calling `bind(robj.vertexarray)` or together with the shader by calling
`bind(robj)`.
"""
struct RenderObject{S <: AbstractShader, VA <: AbstractVertexArray}
    shader::S
    vertex_array::VA

    function RenderObject(shader::S, vertex_array::VA) where {
            S <: AbstractShader, VA <: AbstractVertexArray
        }
        # Otherwise the vertex_array maybe overwritten
        unbind(vertex_array)
        new{S, VA}(shader, vertex_array)
    end
end

function bind(r::RenderObject)
    bind(r.shader)
    bind(r.vertex_array)
end
function unbind(r::RenderObject)
    unbind(r.shader)
    unbind(r.vertex_array)
end
function destroy(r::RenderObject)
    # TODO this is dangerous!
    # Shaders may be reused...
    destroy(r.shader)
    destroy(r.vertex_array)
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
destroy(scene::Scene) = destroy.(scene.render_objects)

camera(scene::Scene) = scene.camera


# TODO
# figure out what this should really be
# implement
#   - deleteat!, pop!
#   - iteration
#   - length, size
#   - maybe draw_indexed?
