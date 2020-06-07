
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




function Quad(position::Vec2, widths::Vec2)
    Quad(Vec2f0(position), Vec2f0(widths))
end
function Quad(p::Vec2f0, w::Vec2f0)
    vertices = Float32[0, 0, 1, 0, 0, 1, 1, 1]
    layout = Hazel.BufferLayout(position = Point2f0)
    vertex_buffer = Hazel.VertexBuffer(vertices, layout)
    index_buffer = Hazel.IndexBuffer(UInt32[0, 1, 2, 1, 2, 3])
    transform = Hazel.translationmatrix(Vec3f0(p..., 0)) *
                Hazel.scalematrix(Vec3f0(w..., 1))

    Hazel.RenderObject(
        Hazel.Shader(joinpath(Hazel.assetpath, "shaders", "flat_color.glsl")),
        Hazel.VertexArray(vertex_buffer, index_buffer),
        Dict{String, Any}("u_transform" => transform)
    )
end


end
