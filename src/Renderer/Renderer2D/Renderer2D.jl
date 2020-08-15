
module Renderer2D

using ..Hazel


"""
    Renderer.init!([; kwargs...])

Intializes/Configures the renderer.
"""
function init!(; kwargs...)
    Hazel.RenderCommand.init!()
    blank_texture[] = Hazel.Texture2D(fill(RGBA(1, 1, 1, 1), 1, 1))
    nothing
end

resize!(width, height) = Hazel.RenderCommand.viewport(0, 0, width, height)

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
@HZ_profile function submit(robj::Hazel.AbstractRenderObject; kwargs...)
    Hazel.bind(robj)
    for (name, value) in kwargs
        Hazel.upload!(robj.shader, name, value)
    end
    Hazel.render(robj)
end


# Includes
include("batch_rendering.jl")

end
