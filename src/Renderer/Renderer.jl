# TODO maybe?
# Cherno implents
#    SceneBegin()
#    submit()
#    SceneEnd()
#
# I think we may want
#    scene = Scene(static_stuf...)
#    push!(scene, render_object)
#    render(::Renderer, scene)
# prolly with staticaly sized and dynamic scenes
#
# StaticScene could be used the same way as Cherno
#   Scene(static_stuff..., render_objs...)
# constructed inside the renderloop
#
# Dynamic scenes would remain the same between iterations
# of the renderloop. I.e. they'd change when explictly told
# to by push! or deleteat! or pop! or something

module Renderer

using ..Hazel


"""
    Renderer.init!([; kwargs...])

Intializes/Configures the renderer.
"""
init!(kwargs...) = Hazel.init!(Hazel.RenderCommand, kwargs...)

resize!(width, height) = Hazel.viewport(r.rc, 0, 0, width, height)

"""
    Renderer.submit(scene[; uniforms])

Draws a `scene` with the given uniforms.
"""
function submit(scene::Hazel.AbstractScene; kwargs...)
    for robj in scene.render_objects
        submit(robj, u_porjection_view = Hazel.projection_view(scene.camera); kwargs...)
    end
end


"""
    Renderer.submit(render_object[; uniforms])

Draws a `render_object` with the given uniforms.
"""
function submit(robj::Hazel.RenderObject; kwargs...)
    Hazel.bind(robj)
    for (name, value) in kwargs
        Hazel.upload!(robj.shader, name, value)
    end
    Hazel.draw_indexed(Hazel.RenderCommand, robj.vertex_array)
end


end
