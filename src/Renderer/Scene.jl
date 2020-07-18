abstract type AbstractRenderObject end

# every AbstractRenderObject must implement either
# Base.convert(::Type{RenderObject}, wrapped::AbstractRenderObject)
# which returns a standard ::RenderObject
# or the methods of RenderObject

"""
    RenderObject(shader, vertex_array)

Creates a new RenderObject that can be pushed to the scene.

Calls `unbind(vertex_array)` to avoid accidental overwriting. You may bind it
again by calling `bind(robj.vertexarray)` or together with the shader by calling
`bind(robj)`.
"""
struct RenderObject{S <: AbstractShader, VA <: AbstractVertexArray} <: AbstractRenderObject
    shader::S
    vertex_array::VA
    uniforms::Dict{String, Any}

    @HZ_profile function RenderObject(
            shader::S,
            vertex_array::VA,
            uniforms::Dict{String, Any}
        ) where {
            S <: AbstractShader, VA <: AbstractVertexArray
        }
        # Otherwise the vertex_array maybe overwritten
        unbind(vertex_array)
        new{S, VA}(shader, vertex_array, uniforms)
    end
end

function RenderObject(shader, vertex_array; kwargs...)
    RenderObject(
        shader,
        vertex_array,
        Dict{String, Any}(Pair(string(k), v) for (k, v) in kwargs)
    )
end

# convert interface
bind(wrapped::AbstractRenderObject) = bind(convert(RenderObject, wrapped))
unbind(wrapped::AbstractRenderObject) = unbind(convert(RenderObject, wrapped))
destroy(wrapped::AbstractRenderObject) = destroy(convert(RenderObject, wrapped))
render(wrapped::AbstractRenderObject) = render(convert(RenderObject, wrapped))
Base.getindex(wrapped::AbstractRenderObject, key) = getindex(convert(RenderObject, wrapped), key)
Base.setindex!(wrapped::AbstractRenderObject, value, key) = setindex!(convert(RenderObject, wrapped), value, key)

@HZ_profile function bind(r::RenderObject)
    bind(r.shader)
    bind(r.vertex_array)
end
@HZ_profile function unbind(r::RenderObject)
    unbind(r.shader)
    unbind(r.vertex_array)
end
function destroy(r::RenderObject)
    # TODO this is dangerous!
    # Shaders may be reused...
    destroy(r.shader)
    destroy(r.vertex_array)
end

@HZ_profile function render(r::RenderObject)
    # This
    for (k, v) in r.uniforms
        Hazel.upload!(r.shader, k, v)
    end
    Hazel.draw_indexed(Hazel.RenderCommand, r.vertex_array)
end

Base.getindex(r::RenderObject, key::String) = getindex(r.uniforms, key)
@HZ_profile function Base.setindex!(r::RenderObject, value, key::String)
    setindex!(r.uniforms, value, key)
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
@HZ_profile Scene(camera::AbstractCamera) = Scene(camera, RenderObject[])
@HZ_profile Scene(camera::AbstractCamera, robjs::AbstractRenderObject...) = Scene(camera, RenderObject[robjs...])
Base.push!(scene::Scene, robj::RenderObject) = push!(scene.render_objects, robj)
destroy(scene::Scene) = destroy.(scene.render_objects)

camera(scene::Scene) = scene.camera
@HZ_profile function render(scene::Scene)
    for robj in scene.render_objects
        render(robj)
    end
end


# TODO
# figure out what this should really be
# implement
#   - deleteat!, pop!
#   - iteration
#   - length, size
#   - maybe draw_indexed?
