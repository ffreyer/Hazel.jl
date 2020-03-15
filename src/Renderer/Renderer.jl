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
    submit(::Renderer, scene[, transform = I])

Draw a given `scene`.
"""
function submit(r::Renderer, scene::AbstractScene, transform::Mat4f0 = Mat4f0(I))
    for robj in scene.render_objects
        submit(r, robj, projection_view(scene.camera), transform)
    end
end


"""
    submit(::Renderer, render_object[, transform = I])

Draw a given `render_object`.
"""
function submit(
        r::Renderer, robj::RenderObject,
        projection_view = Mat4f0(I), transform::Mat4f0 = Mat4f0(I)
    )
    bind(robj)
    upload!(robj.shader, u_projection_view = projection_view)
    upload!(robj.shader, u_transform = transform) # transform
    draw_indexed(r.rc, robj.vertex_array)
end
