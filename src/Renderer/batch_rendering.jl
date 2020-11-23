function blank_texture()
    # Is this a terrible idea?
    if !isdefined(Hazel, :BLANK_TEXTURE)
        @eval Hazel begin
            const BLANK_TEXTURE = Texture2D(fill(RGBA(1, 1, 1, 1), 1, 1))
        end
    else
        return Hazel.BLANK_TEXTURE
    end
end


################################################################################
### (Quad) Components
################################################################################

# Name
# SimpleTexture
# ColorComponent
# Transform2D (semi-internal)
# QuadVertices (internal)
# IsVisible
# TilingFactor

@component struct NameComponent
    name::String
end
NameComponent() = NameComponent("Unnamed Entity")

@component struct SimpleTexture
    texture::Texture2D
end
SimpleTexture() = blank_texture()
SimpleTexture(tex::SubTexture) = SimpleTexture(tex.texture)
destroy(t::SimpleTexture) = destroy(t.texture)

@component struct ColorComponent
    color::Vec4f0
end
ColorComponent() = Vec4f0(1)

@component struct Transform2D
    position::Vec3f0
    rotation::Float32
    scale::Vec2f0
    T::Mat4f0
    has_changed::Bool
end
function Transform2D(position = Vec3f0(0), rotation = 0f0, scale = Vec2f0(1))
    T = translationmatrix(position) * rotationmatrix_z(rotation) * 
        scalematrix(Vec3f0(scale[1], scale[2], 1))
    Transform2D(
        _pad(Vec3f0, position, 0), 
        Float32(rotation), 
        _pad(Vec3f0, scale, 1.0), T, true
    )
end
# convenience
function Transform2D(
        t::Transform2D; 
        position=t.position, rotation=t.rotation, scale=t.scale, has_changed=true
    )
    T = translationmatrix(position) * rotationmatrix_z(rotation) * 
        scalematrix(Vec3f0(scale[1], scale[2], 1))
    Transform2D(position, rotation, scale, T, has_changed)
end

@component struct QuadVertices
    # for efficiency - needs to derived on Transform2D update
    positions::NTuple{4, Vec3f0}
    uv::LRBT{Float32}
end
function QuadVertices()
    QuadVertices((
        Vec3f0(-0.5, -0.5, 0), Vec3f0( 0.5, -0.5, 0), 
        Vec3f0(-0.5,  0.5, 0), Vec3f0( 0.5,  0.5, 0)
    ), LRBT{Float32}(0, 1, 0, 1))
end
function QuadVertices(transform::Transform2D, uv = LRBT{Float32}(0, 1, 0, 1))
    T = transform.T
    QuadVertices((
        T * Vec4f0(-0.5, -0.5, 0, 1), T * Vec4f0( 0.5, -0.5, 0, 1), 
        T * Vec4f0(-0.5,  0.5, 0, 1), T * Vec4f0( 0.5,  0.5, 0, 1)
    ), uv)
end

@component struct IsVisible
    val::Bool
end
IsVisible() = IsVisible(true)

@component struct TilingFactor
    tf::Float32
end
TilingFactor() = TilingFactor(1f0)



################################################################################
### Quad (Entity)
################################################################################



struct WrappedEntity
    parent::Scene
    entity::Entity
end

# This generates a Quad entity
function addQuad!(
        scene::Scene, args...;
        position::Vec3f0=Vec3f0(0), size::Vec2f0=Vec2f0(1), rotation = 0f0,
        color::Vec4f0 = Vec4f0(1), texture = blank_texture(), 
        tilingfactor::Float32 = 1f0, visible::Bool = true,
        uv::LRBT = uv(texture), name::String = "Unnamed Entity"
    )
    transform = Transform2D(position, rotation, size)
    e = Entity(registry(scene),
        transform, QuadVertices(transform, uv),
        ColorComponent(color),
        SimpleTexture(texture),
        TilingFactor(tilingfactor),
        IsVisible(visible),
        NameComponent(name),
        args...
    )
    WrappedEntity(scene, e)
end

moveto!(we::WrappedEntity, val) = moveto!(we.parent, we.entity, val)
moveby!(we::WrappedEntity, val) = moveby!(we.parent, we.entity, val)
scaleto!(we::WrappedEntity, val) = scaleto!(we.parent, we.entity, val)
scaleby!(we::WrappedEntity, val) = scaleby!(we.parent, we.entity, val)
rotateto!(we::WrappedEntity, val) = rotateto!(we.parent, we.entity, val)
rotateby!(we::WrappedEntity, val) = rotateby!(we.parent, we.entity, val)
setcolor!(we::WrappedEntity, val) = setcolor!(we.parent, we.entity, val)

registry(we::WrappedEntity) = registry(we.parent)
Base.push!(we::WrappedEntity, component) = registry(we)[we.entity] = component
Base.haskey(we::WrappedEntity, key) = we.entity in registry(we)[key]
Base.in(key, we::WrappedEntity) = we.entity in registry(we)[key]
Base.getindex(we::WrappedEntity, key) = registry(we)[key][e]
Base.setindex!(we::WrappedEntity, val, key) = registry(we)[key][e] = val
Base.delete!(we::WrappedEntity) = delete!(registry(we), we.entity)
Base.delete!(we::WrappedEntity, key) = pop!(registry(we)[key], we.entity)
Base.pop!(we::WrappedEntity, key) = pop!(registry(we)[key], we.entity)


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

function QuadVertex(p, c::ColorComponent, uv, ti, tf::TilingFactor)
    QuadVertex(p, c.color, uv, ti, tf.tf)
end



# This will take care of batching and rendering quads
struct BatchRenderer <: System
    camera::OrthographicCamera

    vertex_buffer::Vector{QuadVertex}
    texture_buffer::Vector{Texture2D}

    va::VertexArray
    shader::Shader

    max_quads::Int
    max_quad_vertices::Int
    max_quad_indices::Int
    max_texture_slots::Int
end

function BatchRenderer(camera::OrthographicCamera;
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
    for i in eachindex(texture_buffer)
        texture_buffer[i] = blank_texture()
    end

    BatchRenderer(
        camera,
        Vector{QuadVertex}(undef, max_quad_vertices), texture_buffer,
        vertex_array, shader,
        max_quads, max_quad_vertices, max_quad_indices, max_texture_slots,
    )
end

requested_components(::BatchRenderer) = (
    SimpleTexture, ColorComponent, QuadVertices, IsVisible, TilingFactor
)

function update(br::BatchRenderer, reg::AbstractLedger)
    textures        = reg[SimpleTexture]
    colors          = reg[ColorComponent]
    quads           = reg[QuadVertices]
    visibles        = reg[IsVisible]
    tilingfactors   = reg[TilingFactor]

    bind(br.shader)
    bind(br.va)

    vb = br.vertex_buffer
    tb = br.texture_buffer
    vidx = 1
    tidx = 0
    for e in @entities_in(textures && colors && quads && visibles && tilingfactors)
        # visibles[e].val || continue

        # Flush buffer (render) if full
        if vidx > br.max_quad_vertices
            upload!(vertex_buffer(br.va), vb)
            for i in 1:tidx
                bind(tb[i], i)
            end
            # TODO uniforms (if there were any...)
            upload!(br.shader, u_projection_view = projection_view(br.camera))
            RenderCommand.draw_indexed(br.va, br.max_quad_indices)
        end

        # Maybe add texture, get texture index
        tex = textures[e].texture
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
        c = colors[e]
        tf = tilingfactors[e]
        q = quads[e]
        l,r,b,t = q.uv
        vb[vidx]   = QuadVertex(q.positions[1], c, Vec2f0(l, b), current_texture-1, tf)
        vb[vidx+1] = QuadVertex(q.positions[2], c, Vec2f0(r, b), current_texture-1, tf)
        vb[vidx+2] = QuadVertex(q.positions[3], c, Vec2f0(l, t), current_texture-1, tf)
        vb[vidx+3] = QuadVertex(q.positions[4], c, Vec2f0(r, t), current_texture-1, tf)
        vidx += 4
    end

    # Render all set
    # Not sure if views are gucci
    @views upload!(vertex_buffer(br.va), vb[1:vidx-1])
    # upload!(vertex_buffer(br.va), vb)
    for i in 1:tidx
        bind(tb[i], i)
    end
    upload!(br.shader, u_projection_view = projection_view(br.camera))
    RenderCommand.draw_indexed(br.va, 6vidx-6)

    nothing
end

destroy(br::BatchRenderer) = begin destroy(br.va); destroy(br.shader) end



# This applies a change in Transform2D to QuadVertices
# ... in a non-mutable, non-Observable way
# ... that avoid recalculations when possible
# ... I hope I didn't overthink this
struct ApplyTransform <: System end

requested_components(::ApplyTransform) = (Transform2D, QuadVertices)
function update(::ApplyTransform, reg::AbstractLedger)
    transforms = reg[Transform2D]
    quads = reg[QuadVertices]

    for e in @entities_in(transforms && quads)
        T = transforms[e]
        T.has_changed || continue
        transforms[e] = Transform2D(T, has_changed=false)
        # generate new, correctly placed quad
        quads[e] = QuadVertices(T, quads[e].uv)
    end
    nothing
end




# This stage should do rendering of batched quads
# maybe create automatically on addQuad!()?
function addBatchRenderingStage!(scene::Scene; kwargs...)
    stage = Stage(
        :BatchRenderingStage, 
        [ApplyTransform(), BatchRenderer(scene.camera; kwargs...)]
    )
    push!(scene, stage)
end



################################################################################
### Utilities
################################################################################



function _recalculate!(scene::Scene, e::Entity)
    T = scene[Transform2D][e]
    q = scene[QuadVertices][e]
    scene[QuadVertices][e] = QuadVertices(T, q.uv)
    nothing
end


function moveto!(s::Scene, e::Entity, p::Vec3f0)
    s[Transform2D][e] = Transform2D(s[Transform2D][e], position = p, has_changed=false)
    _recalculate!(s, e)
end
moveto!(s::Scene, e::Entity, p::Vec2f0) = moveto!(s, e, Vec3f0(p..., q.position[3]))
function moveby!(s::Scene, e::Entity, v::Vec3f0)
    T = s[Transform2D][e]
    s[Transform2D][e] = Transform2D(T, position = T.position .+ v, has_changed=false)
    _recalculate!(s, e)
end
moveby!(s::Scene, e::Entity, v::Vec2f0) = moveto!(s, e, Vec3f0(v..., 0))


function rotateto!(s::Scene, e::Entity, θ::Float32)
    T = s[Transform2D][e]
    s[Transform2D][e] = Transform2D(T, rotation = θ, has_changed=false)
    _recalculate!(s, e)
end
function rotateby!(s::Scene, e::Entity, θ::Float32)
    T = s[Transform2D][e]
    s[Transform2D][e] = Transform2D(T, rotation = T.rotation+θ, has_changed=false)
    _recalculate!(s, e)
end


function scaleto!(scene::Scene, e::Entity, s::Vec3f0)
    T = scene[Transform2D][e]
    scene[Transform2D][e] = Transform2D(T, scale = s, has_changed=false)
    _recalculate!(scene, e)
end
scaleto!(scene::Scene, e::Entity, s::Real) = scaleto!(scene, e, Float32(s))
scaleto!(scene::Scene, e::Entity, s::Float32) = scaleto!(scene, e, Vec3f0(s, s, 1.0))
scaleto!(scene::Scene, e::Entity, s::Vec2f0) = scaleto!(scene, e, Vec3f0(s..., 1.0))


function scaleby!(scene::Scene, e::Entity, s::Vec3f0)
    T = scene[Transform2D][e]
    scene[Transform2D][e] = Transform2D(T, scale = T.scale .* s, has_changed=false)
    _recalculate!(scene, e)
end 
scaleby!(scene::Scene, e::Entity, s::Real) = scaleby!(scene, e, Float32(s))
scaleby!(scene::Scene, e::Entity, s::Float32) = scaleby!(scene, e, Vec2f0(s))
scaleby!(scene::Scene, e::Entity, s::Vec2f0) = scaleby!(scene, e, Vec3f0(s..., 1.0))


function setcolor!(scene::Scene, e::Entity, color::Vec4f0)
    scene[ColorComponent][e] = ColorComponent(color)
end

_pad(::Type{Vec3f0}, v::Float32, p) = Vec3f0(v, p, p)
_pad(::Type{Vec3f0}, v::Vec2f0, p) = Vec3f0(v[1], v[2], p)
_pad(::Type{Vec3f0}, v::Vec3f0, p) = v

_pad(::Type{Vec4f0}, v::Float32, p) = Vec4f0(v, p, p, p)
_pad(::Type{Vec4f0}, v::Vec2f0, p) = Vec4f0(v[1], v[2], p, p)
_pad(::Type{Vec4f0}, v::Vec3f0, p) = Vec4f0(v[1], v[2], v[3], p)
_pad(::Type{Vec4f0}, v::Vec4f0, p) = v