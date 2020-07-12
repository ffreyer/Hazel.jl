
module Renderer2D

using ..Hazel


"""
    Renderer.init!([; kwargs...])

Intializes/Configures the renderer.
"""
function init!(kwargs...)
    Hazel.init!(Hazel.RenderCommand, kwargs...)
    nothing
end

resize!(width, height) = Hazel.viewport(Hazel.RenderCommand, 0, 0, width, height)

"""
    Renderer2D.submit(scene[; uniforms])

Draws a `scene` with the given uniforms.
"""
@HZ_profile function submit(scene::Hazel.AbstractScene; kwargs...)
    for robj in scene.render_objects
        submit(robj, u_projection_view = Hazel.projection_view(scene.camera); kwargs...)
    end
end


"""
    Renderer2D.submit(render_object[; uniforms])

Draws a `render_object` with the given uniforms.
"""
@HZ_profile function submit(robj::Hazel.RenderObject; kwargs...)
    Hazel.bind(robj)
    for (name, value) in kwargs
        Hazel.upload!(robj.shader, name, value)
    end
    Hazel.render(robj)
end




function Quad(position::Vec2, widths::Vec2; uniforms...)
    Quad(Vec3f0(position..., 0), Vec3f0(widths..., 0); uniforms...)
end
@HZ_profile function Quad(p::Vec3f0, w::Vec3f0; kwargs...)
    transform = Hazel.translationmatrix(p) * Hazel.scalematrix(w)
    uniforms = Dict{String, Any}(Pair(string(k), v) for (k, v) in kwargs)
    uniforms["u_transform"] = transform

    vertices = Float32[0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0, 1, 1, 1, 1, 1]
    layout = Hazel.BufferLayout(position = Point2f0, uv = Point2f0)
    vertex_buffer = Hazel.VertexBuffer(vertices, layout)
    index_buffer = Hazel.IndexBuffer(UInt32[0, 1, 2, 1, 2, 3])

    haskey(uniforms, "u_color") || (uniforms["u_color"] = Vec4f0(1))
    if !haskey(uniforms, "u_texture")
        uniforms["u_texture"] = Hazel.Texture2D(fill(RGBA(1, 1, 1, 1), 1, 1))
    end
    shader = Hazel.Shader(joinpath(Hazel.assetpath, "shaders", "texture.glsl"))

    Hazel.RenderObject(
        shader,
        Hazel.VertexArray(vertex_buffer, index_buffer),
        uniforms
    )
end


end
