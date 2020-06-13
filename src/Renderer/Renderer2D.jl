
module Renderer2D

using ..Hazel

"""
    Renderer.init!([; kwargs...])

Intializes/Configures the renderer.
"""
init!(kwargs...) = Hazel.init!(Hazel.RenderCommand, kwargs...)

resize!(width, height) = Hazel.viewport(r.rc, 0, 0, width, height)

"""
    Renderer2D.submit(scene[; uniforms])

Draws a `scene` with the given uniforms.
"""
function submit(scene::Hazel.AbstractScene; kwargs...)
    for robj in scene.render_objects
        submit(robj, u_projection_view = Hazel.projection_view(scene.camera); kwargs...)
    end
end


"""
    Renderer2D.submit(render_object[; uniforms])

Draws a `render_object` with the given uniforms.
"""
function submit(robj::Hazel.RenderObject; kwargs...)
    Hazel.bind(robj)
    for (name, value) in kwargs
        Hazel.upload!(robj.shader, name, value)
    end
    Hazel.render(robj)
end




function Quad(position::Vec2, widths::Vec2; uniforms...)
    Quad(Vec3f0(position..., 0), Vec3f0(widths..., 0); uniforms...)
end
function Quad(p::Vec3f0, w::Vec3f0; kwargs...)
    transform = Hazel.translationmatrix(p) * Hazel.scalematrix(w)
    uniforms = Dict{String, Any}(Pair(string(k), v) for (k, v) in kwargs)
    uniforms["u_transform"] = transform

    if haskey(uniforms, "u_texture")
        vertices = Float32[0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0, 1, 1, 1, 1, 1]
        layout = Hazel.BufferLayout(position = Point2f0, uv = Point2f0)
    else
        vertices = Float32[0, 0, 1, 0, 0, 1, 1, 1]
        layout = Hazel.BufferLayout(position = Point2f0)
    end
    vertex_buffer = Hazel.VertexBuffer(vertices, layout)
    index_buffer = Hazel.IndexBuffer(UInt32[0, 1, 2, 1, 2, 3])

    if haskey(uniforms, "u_color")
        shader = Hazel.Shader(joinpath(Hazel.assetpath, "shaders", "flat_color.glsl"))
    elseif haskey(uniforms, "u_texture")
        shader = Hazel.Shader(joinpath(Hazel.assetpath, "shaders", "texture.glsl"))
    else
        throw(ErrorException("Neither 'u_color' nor 'u_texture' has been passed."))
    end

    Hazel.RenderObject(
        shader,
        Hazel.VertexArray(vertex_buffer, index_buffer),
        uniforms
    )
end


end
