@doc """
    InstancedQuad(transform, texture; kwargs...)

Creates instanced quad component, i.e. a Quad that is part of the batch 
rendering System. The `transform` is a transform component. (It is used to avoid
recalculating positions of static Quads.)

kwargs include:
* `color`
* `tilingfactor`
* `visible`
* `uv`
""" InstancedQuad
@component mutable struct InstancedQuad
    positions::NTuple{4, Vec3f0}
    uv::LRBT{Float32}
    tilingfactor::Float32
    texture::Texture2D
    color::Vec4f0
    visible::Bool
end

function InstancedQuad(transform, texture::SubTexture; kwargs...)
    InstancedQuad(transform, texture.texture; kwargs...)
end
function InstancedQuad(
        transform::Transform, texture::Texture2D;
        color = Vec4f0(1,1,1,1),
        uv = LRBT{Float32}(0,1,0,1),
        tilingfactor = 1f0,
        visible = true
    )
    T = transform.transform
    InstancedQuad(
        (
            T * Vec4f0(-0.5, -0.5, 0, 1), T * Vec4f0( 0.5, -0.5, 0, 1), 
            T * Vec4f0(-0.5,  0.5, 0, 1), T * Vec4f0( 0.5,  0.5, 0, 1)
        ), 
        uv, tilingfactor,
        texture, color, visible
    )
end


################################################################################
### Quad (Entity)
################################################################################


struct Quad <: WrappedEntity
    entity::Entity
end
Quad(scene::Scene, e::RawEntity) = Quad(Entity(scene, e))


# This generates a Quad entity
function addQuad!(
        scene::Scene, args...; name::String = "Unnamed Quad",
        position = Vec3f0(0), size = Vec3f0(1), rotation = Vec3f0(0),
        texture = blank_texture(scene), uv::LRBT = uv(texture), kwargs...
    )
    transform = Transform(position, rotation, size)
    e = Entity(scene,
        NameComponent(name),
        transform, 
        InstancedQuad(transform, texture, uv = uv; kwargs...),
        args...
    )
    Quad(e)
end



################################################################################
### Rendering (Systems)
################################################################################



# One blob of data in the vertex_array that's sent to the GPU
# This is mostly for convenience
struct QuadVertex
    position::Vec3f0
    color::Vec4f0
    uv::Vec2f0
    texture_index::Float32
    tilingfactor::Float32
end



# This will take care of batching and rendering quads
struct BatchRenderer <: System
    vertex_buffer::Vector{QuadVertex}
    texture_buffer::Vector{Texture2D}

    va::VertexArray
    shader::Shader

    max_quads::Int
    max_quad_vertices::Int
    max_quad_indices::Int
    max_texture_slots::Int
end

function BatchRenderer(;
        max_quads = 10_000,
        max_quad_vertices = 4max_quads,
        max_quad_indices = 6max_quads,
        max_texture_slots = 32
    )
    # This sets up depth test, blending etc. Technically should be a per-render
    Hazel.RenderCommand.init!()

    layout = BufferLayout(
        position = Vec3f0, color = Vec4f0, uv = Vec2f0,
        texture_index = Float32, tilingfactor = Float32
    )
    vertex_buffer = Hazel.VertexBuffer(max_quad_vertices, layout)
    indices = UInt32[4o+i for o in 0:max_quads-1 for i in [0, 1, 2, 2, 3, 1]]
    index_buffer = IndexBuffer(indices)
    vertex_array = VertexArray(vertex_buffer, index_buffer)
    # for savety
    Hazel.unbind(vertex_array)

    shader = Hazel.Shader(joinpath(Hazel.assetpath, "shaders", "texture.glsl"))
    Hazel.bind(shader)
    Hazel.upload!(shader, "u_texture", Int32.(collect(0:max_texture_slots-1)))

    texture_buffer = Vector{Texture2D}(undef, max_texture_slots)

    BatchRenderer(
        Vector{QuadVertex}(undef, max_quad_vertices), texture_buffer,
        vertex_array, shader,
        max_quads, max_quad_vertices, max_quad_indices, max_texture_slots,
    )
end

requested_components(::BatchRenderer) = (InstancedQuad,)

function update!(app, br::BatchRenderer, reg::AbstractLedger, ts)
    # Find active camera
    cameras = reg[CameraComponent]
    trg = nothing
    for e in @entities_in(cameras) # I think this just works?
        if cameras[e].active
            trg = e
            break
        end
    end
    trg === nothing && return
    projection_view = cameras[trg].projection_view


    # Render
    quads = reg[InstancedQuad]

    bind(br.shader)
    bind(br.va)

    vb = br.vertex_buffer
    tb = br.texture_buffer
    vidx = 1
    tidx = 0
    for e in @entities_in(quads)
        quad = quads[e]
        quad.visible || continue

        # Flush buffer (render) if full
        if vidx > br.max_quad_vertices
            upload!(vertex_buffer(br.va), vb)
            for i in 1:tidx
                bind(tb[i], i)
            end
            # TODO uniforms (if there were any...)
            upload!(br.shader, u_projection_view = projection_view)
            RenderCommand.draw_indexed(br.va, br.max_quad_indices)
            vidx = 1
            tidx = 0
        end

        # Maybe add texture, get texture index
        tex = quad.texture
        current_texture = 1
        while true
            if current_texture > tidx
                tb[current_texture] = tex
                tidx += 1
                break
            end
            id(tb[current_texture]) == id(tex) && break
            current_texture += 1
        end

        # Build each QuadVertex
        c = quad.color
        tf = quad.tilingfactor
        positions = quad.positions
        l,r,b,t = quad.uv

        vb[vidx]   = QuadVertex(positions[1], c, Vec2f0(l, b), current_texture-1, tf)
        vb[vidx+1] = QuadVertex(positions[2], c, Vec2f0(r, b), current_texture-1, tf)
        vb[vidx+2] = QuadVertex(positions[3], c, Vec2f0(l, t), current_texture-1, tf)
        vb[vidx+3] = QuadVertex(positions[4], c, Vec2f0(r, t), current_texture-1, tf)
        vidx += 4
    end

    # Render all set
    @views upload!(vertex_buffer(br.va), vb[1:vidx-1])
    for i in 1:tidx
        bind(tb[i], i)
    end
    upload!(br.shader, u_projection_view = projection_view)
    RenderCommand.draw_indexed(br.va, 6vidx-6)

    nothing
end

destroy(br::BatchRenderer) = begin destroy(br.va); destroy(br.shader) end



# This applies a change in Transform to QuadVertices
# ... in a non-mutable, non-Observable way
# ... that avoid recalculations when possible
# ... I hope I didn't overthink this
struct ApplyTransform <: System end

requested_components(::ApplyTransform) = (Transform, InstancedQuad)
function update!(app, ::ApplyTransform, reg::AbstractLedger, ts)
    transforms = reg[Transform]
    quads = reg[InstancedQuad]

    for e in @entities_in(transforms && quads)
        T = transforms[e]
        if T.has_changed
            T.has_changed = false
            # generate new, correctly placed quad
            quads[e].positions = (
                T.transform * Vec4f0(-0.5, -0.5, 0, 1), 
                T.transform * Vec4f0( 0.5, -0.5, 0, 1), 
                T.transform * Vec4f0(-0.5,  0.5, 0, 1), 
                T.transform * Vec4f0( 0.5,  0.5, 0, 1)
            )
        end
    end
    nothing
end




# This stage should do rendering of batched quads
# maybe create automatically on addQuad!()?
function addBatchRenderingStage!(scene::Scene; kwargs...)
    stage = Stage(
        :BatchRenderingStage, 
        [ApplyTransform(), BatchRenderer(; kwargs...)]
    )
    push!(scene, stage)
end



################################################################################
### Utilities
################################################################################



# These function handle the "has_changed = true" update on their own
function _recalculate!(quad::Quad)
    T = quad[Transform]
    Q = quad[InstancedQuad]
    Q.positions = (
        T.transform * Vec4f0(-0.5, -0.5, 0, 1), 
        T.transform * Vec4f0( 0.5, -0.5, 0, 1), 
        T.transform * Vec4f0(-0.5,  0.5, 0, 1), 
        T.transform * Vec4f0( 0.5,  0.5, 0, 1)
    )
    nothing
end


function moveto!(quad::Quad, p::Vec3f0)
    t = quad[Transform]
    setfield!(t, :translation, p)
    setfield!(t, :transform, transform(t.translation, t.rotation, t.scale))
    _recalculate!(quad)
end
moveto!(quad::Quad, p::Vec2f0) = moveto!(quad, Vec3f0(p..., quad[Transform].position[3]))
function moveby!(quad::Quad, v::Vec3f0)
    t = quad[Transform]
    setfield!(t, :translation, t.translation .+ v)
    setfield!(t, :transform, translationmatrix(v) * t.transform)
    _recalculate!(quad)
end
moveby!(quad::Quad, v::Vec2f0) = moveto!(quad, Vec3f0(v..., 0))


function rotateto!(quad::Quad, θ::Float32)
    t = quad[Transform]
    setfield!(t, :rotation, Vec3f0(0, 0, θ))
    setfield!(t, :transform, transform(t.translation, t.rotation, t.scale))
    _recalculate!(quad)
end
function rotateby!(quad::Quad, θ::Float32)
    t = quad[Transform]
    setfield!(t, :rotation, Vec3f0(0, 0, t.rotation[3] + θ))
    setfield!(t, :transform, transform(t.translation, t.rotation, t.scale))
    _recalculate!(quad)
end


function scaleto!(quad::Quad, s::Vec3f0)
    t = quad[Transform]
    setfield!(t, :scale, s)
    setfield!(t, :transform, transform(t.translation, t.rotation, t.scale))
    _recalculate!(quad)
end
scaleto!(quad::Quad, s::Real) = scaleto!(quad, Float32(s))
scaleto!(quad::Quad, s::Float32) = scaleto!(quad, Vec3f0(s, s, 1.0))
scaleto!(quad::Quad, s::Vec2f0) = scaleto!(quad, Vec3f0(s..., 1.0))


function scaleby!(quad::Quad, s::Vec3f0)
    t = quad[Transform]
    setfield!(t, :scale, t.scale .* s)
    setfield!(t, :transform, t.transform * scalematrix(s))
    _recalculate!(quad)
end 
scaleby!(quad::Quad, s::Real) = scaleby!(quad, Float32(s))
scaleby!(quad::Quad, s::Float32) = scaleby!(quad, Vec2f0(s))
scaleby!(quad::Quad, s::Vec2f0) = scaleby!(quad, Vec3f0(s..., 1.0))


function setcolor!(quad::Quad, color::Vec4f0)
    quad[ColorComponent] = ColorComponent(color)
end

# Why am I not using these?
_pad(::Type{Vec3f0}, v::Float32, p) = Vec3f0(v, p, p)
_pad(::Type{Vec3f0}, v::Vec2f0, p) = Vec3f0(v[1], v[2], p)
_pad(::Type{Vec3f0}, v::Vec3f0, p) = v

_pad(::Type{Vec4f0}, v::Float32, p) = Vec4f0(v, p, p, p)
_pad(::Type{Vec4f0}, v::Vec2f0, p) = Vec4f0(v[1], v[2], p, p)
_pad(::Type{Vec4f0}, v::Vec3f0, p) = Vec4f0(v[1], v[2], v[3], p)
_pad(::Type{Vec4f0}, v::Vec4f0, p) = v