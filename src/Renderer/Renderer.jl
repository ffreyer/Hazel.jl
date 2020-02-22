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
"""
    Renderer()

Creates a `Renderer` which handles draw calls.
"""
struct Renderer{T <: AbstractRenderCommand}
    rc::T
    Renderer() = new{typeof(RenderCommand)}(RenderCommand)
end

"""
    draw_indexed(::Renderer, vertex_array)

Draw a given `vertex_array`.
"""
function draw_indexed(r::Renderer, va::AbstractVertexArray)
    bind(va)
    draw_indexed(r.rc, va)
end

"""
    submit(::Renderer, scene)

Draw a given `scene`.
"""
function submit(r::Renderer, scene::AbstractScene)
    for robj in scene.render_objects
        bind(robj.shader)
        bind(robj.vertex_array)
        upload!(robj.shader, u_projection_view = projection_view(scene.camera))
        draw_indexed(r.rc, robj.vertex_array)
    end
end
