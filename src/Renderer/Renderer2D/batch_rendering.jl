# Limits for a single batch rendered drawcall
const MAX_QUADS = 10_000
const MAX_QUAD_VERTICES = 4MAX_QUADS
const MAX_QUAD_INDICES = 6MAX_QUADS
const MAX_TEXTURE_SLOTS = 32

# TODO this doesn't seem to work :(
# Texture for un-textured quads
# const blank_texture = Hazel.Texture2D(fill(RGBA(1, 1, 1, 1), 1, 1))
const blank_texture = Ref{Hazel.Texture2D}()


# Vertex Data of Quads
struct QuadVertex
    position::Vec3f0
    color::Vec4f0
    uv::Vec2f0
    texture_index::Float32
    tilingfactor::Float32
end

function QuadVertex(q::QuadVertex; 
        position = q.position, 
        color = q.color, 
        uv = q.uv, 
        texture_index = q.texture_index,
        tilingfactor = q.tilingfactor
    )
    QuadVertex(position, color, uv, texture_index, tilingfactor)
end

function Base.show(io::IO, qv::QuadVertex)
    println(io, "QuadVertex")
    println(io, "\tposition = $(qv.position)")
    println(io, "\tcolor = $(qv.color)")
    println(io, "\tuv = $(qv.uv)")
    println(io, "\ttexture_index = $(qv.texture_index)")
    println(io, "\ttilingfactor = $(qv.tilingfactor)")
end

# # Full Quad Data, can be manipulated
mutable struct Quad
    vertices::NTuple{4, QuadVertex}
    position::Vec3f0
    rotation::Float32
    scale::Vec3f0
    texture::Hazel.Texture2D
    visible::Bool
end

function Base.show(io::IO, q::Quad)
    println(io, "Quad" * (q.visible ? "" : " (hidden)"))
    println(io, "\tposition = $(q.position)")
    println(io, "\trotation = $(q.rotation)")
    println(io, "\tscale = $(q.scale)")
    println(io, "\ttexture = $(q.texture.path)")
    println(io, "\ttexture_index = $(q.vertices[1].texture_index)")
end

"""
    Quad(position, size[; rotation, color, texture, tilingfactor, visible])

Creates a `Quad` at the given position with a given size.

Default keyword arguments:
- `rotation = 0f0` in Degrees
- `color = Vec4f0(1)`
- `texture = Renderer2D.blank_texture`
- `tilingfactor = 1f0`
"""
function Quad(
        position::Vec3f0, size::Vec2f0; rotation = 0f0,
        color::Vec4f0 = Vec4f0(1), texture = blank_texture[], 
        tilingfactor::Float32 = 1f0, visible=true
    )
    scale = Vec3f0(size..., 1f0); c = color; tf = tilingfactor
    T = Hazel.translationmatrix(position) *
        Hazel.rotationmatrix_z(rotation) * 
        Hazel.scalematrix(scale)
    return Quad((
        QuadVertex(T * Vec4f0(-0.5, -0.5, 0, 1), c, Vec2f0(0, 0), 0f0, tf),
        QuadVertex(T * Vec4f0( 0.5, -0.5, 0, 1), c, Vec2f0(1, 0), 0f0, tf),
        QuadVertex(T * Vec4f0( 0.5,  0.5, 0, 1), c, Vec2f0(1, 1), 0f0, tf),
        QuadVertex(T * Vec4f0(-0.5,  0.5, 0, 1), c, Vec2f0(0, 1), 0f0, tf)
    ), position, Float32(rotation), scale, texture, visible)
end

function recalculate!(q::Quad)
    T = Hazel.translationmatrix(q.position) *
        Hazel.rotationmatrix_z(q.rotation) * 
        Hazel.scalematrix(q.scale)

    q.vertices = (
        QuadVertex(q.vertices[1], position = T * Vec4f0(-0.5, -0.5, 0, 1)),
        QuadVertex(q.vertices[2], position = T * Vec4f0( 0.5, -0.5, 0, 1)),
        QuadVertex(q.vertices[3], position = T * Vec4f0( 0.5,  0.5, 0, 1)),
        QuadVertex(q.vertices[4], position = T * Vec4f0(-0.5,  0.5, 0, 1))
    )
    nothing
end
Hazel.moveto!(q::Quad, p::Vec3f0) = (q.position = p; recalculate!(q))
Hazel.moveto!(q::Quad, p::Vec2f0) = moveto!(q, Vec3f0(p..., q.position[3]))
Hazel.moveby!(q::Quad, v::Vec3f0) = moveto!(q, q.position + v)
Hazel.moveby!(q::Quad, v::Vec2f0) = moveto!(q, q.position + Vec3f0(v..., 0))

Hazel.rotateto!(q::Quad, θ::Float32) = (q.rotation = θ; recalculate!(q))
Hazel.rotateby!(q::Quad, θ::Float32) = rotateto!(q, q.rotation + θ)

scaleto!(q::Quad, s::Vec2f0) = scaleto!(q, Vec3f0(s..., 1.0))
scaleto!(q::Quad, s::Float32) = scaleto!(q, Vec3f0(s, s, 1.0))
scaleto!(q::Quad, s::Vec3f0) = (q.scale = s; recalculate!(q))
scaleby!(q::Quad, s::Vec3f0) = scaleto!(q, s .* q.scale)
scaleby!(q::Quad, s::Vec2f0) = scaleby!(q, Vec3f0(s..., 1.0))
scaleby!(q::Quad, s::Float32) = scaleto!(q, s * q.scale)
# TODO move these general methods into Hazel
# Hazel.rotateto!(q, θ::Real) = rotateto!(q, Float32(θ))
# Hazel.rotateby!(q, θ::Real) = rotateby!(q, Float32(θ))
scaleto!(q, s::Real) = scaleto!(q, Float32(s))
scaleby!(q, s::Real) = scaleby!(q, Float32(s))
# TODO move this definition to Hazel somewhere
export scaleto!, scaleby!

function setcolor!(q::Quad, color::Vec4f0)
    q.vertices = map(v -> QuadVertex(v, color=color), q.vertices)
end


struct Quads <: Hazel.AbstractRenderObject
    shader::Hazel.Shader
    vertex_array::Hazel.VertexArray
    uniforms::Dict{String, Any}

    quads::Vector{Quad}
    textures::Vector{Hazel.Texture2D}
end

function Quads()
    layout = Hazel.BufferLayout(
        position = Vec3f0, color = Vec4f0, uv = Vec2f0,
        texture_index = Float32, tilingfactor = Float32
    )
    vertex_buffer = Hazel.VertexBuffer(MAX_QUAD_VERTICES, layout)
    indices = UInt32[4o+i for o in 0:MAX_QUADS-1 for i in [0, 1, 2, 2, 3, 0]]
    index_buffer = Hazel.IndexBuffer(indices)
    vertex_array = Hazel.VertexArray(vertex_buffer, index_buffer)
    # for savety
    Hazel.unbind(vertex_array)

    shader = Hazel.Shader(joinpath(Hazel.assetpath, "shaders", "texture.glsl"))
    Hazel.bind(shader)
    Hazel.upload!(shader, "u_texture", Int32.(collect(0:MAX_TEXTURE_SLOTS-1)))

    Quads(
        shader, vertex_array, Dict{String,Any}(),
        Quad[], Hazel.Texture2D[blank_texture[]]
    )
end



function Base.push!(scene::Hazel.AbstractScene, quad::Quad, quads::Quad...)
    _push!(scene, quad, quads...)
end
function _push!(scene::Hazel.AbstractScene, quads::Quad...)
    robjs = filter(robj -> robj isa Quads, Hazel.render_objects(scene))

    if isempty(robjs)
        robj = Quads()
        push!(robjs, robj)
        push!(scene, robj)
    end

    robj_idx = 0
    robj = first(robjs)

    for quad in quads
        success = _push!(robj, quad)

        while !success
            robj_idx += 1
            if robj_idx > length(robjs)
                robj = Quads()
                push!(robjs, robj)
                push!(scene, robj)
            else
                robj = robjs[robj_idx]
            end
            success = _push!(robj, quad)
        end
    end
    scene
end
function _push!(quads::Quads, q::Quad)
    if length(quads.quads) == MAX_QUADS
        return false
    end

    if q.texture === blank_texture[]
        texture_index = 1
    else
        texture_index = findfirst(x -> x == q.texture, quads.textures)
        if texture_index === nothing
            if length(quads.textures) <= MAX_TEXTURE_SLOTS
                push!(quads.textures, q.texture)
                texture_index = length(quads.textures)
            else
                return false
            end
        end
    end

    if texture_index != 1
        q.vertices = (
            QuadVertex(q.vertices[1], texture_index = Float32(texture_index-1)),
            QuadVertex(q.vertices[2], texture_index = Float32(texture_index-1)),
            QuadVertex(q.vertices[3], texture_index = Float32(texture_index-1)),
            QuadVertex(q.vertices[4], texture_index = Float32(texture_index-1))
        )
    end
    push!(quads.quads, q)
    return true
end


# TODO for manipulation
# Base.getindex
# Base.setindex
# Base.pop!
# Base.deleteat!

@HZ_profile function Hazel.render(q::Quads)
    # TODO: Can we reduce allocations here?
    # Hazel.upload!(Hazel.vertex_buffer(q.vertex_array), q.vertices)
    vba = [quad.vertices for quad in q.quads if quad.visible]
    Hazel.upload!(Hazel.vertex_buffer(q.vertex_array), vba)
    for (k, v) in q.uniforms
        Hazel.upload!(q.shader, k, v)
    end
    for (slot, texture) in enumerate(q.textures)
        Hazel.bind(texture, slot)
    end

    Hazel.RenderCommand.draw_indexed(
        q.vertex_array,
        trunc(Int64, 6length(vba))
    )
end

@HZ_profile function Hazel.bind(r::Quads)
    Hazel.bind(r.shader)
    Hazel.bind(r.vertex_array)
end
@HZ_profile function Hazel.unbind(r::Quads)
    Hazel.unbind(r.shader)
    Hazel.unbind(r.vertex_array)
end
function Hazel.destroy(r::Quads)
    # TODO this is dangerous!
    # Shaders may be reused...
    Hazel.destroy(r.shader)
    Hazel.destroy(r.vertex_array)
end
Base.getindex(r::Quads, key::String) = getindex(r.uniforms, key)
@HZ_profile function Base.setindex!(r::Quads, value, key::String)
    setindex!(r.uniforms, value, key)
end







################################################################################
### Old Quad Rendering
################################################################################
#
#
# mutable struct MoveableQuad{S, VA} <: Hazel.AbstractRenderObject
#     position::Vec3f0
#     rotation::Float32
#     scale::Vec3f0
#     robj::Hazel.RenderObject{S, VA}
# end
#
# """
#     MoveableQuad(position, widths; uniforms...)
#
# Constructs a MoveableQuad which implements
# - [`moveto!`](@ref) and [`moveby!`](@ref) for translation
# - [`rotateto!`](@ref) and [`rotateby!`](@ref) for rotation
# - [`scaleto!`](@ref) and [`scaleby!`](@ref) for scaling
#
# See also: [`Quad`](@ref)
# """
# function MoveableQuad(position::Vec2, widths::Vec2; uniforms...)
#     MoveableQuad(Vec3f0(position..., 0), Vec3f0(widths..., 0); uniforms...)
# end
# function MoveableQuad(position::Vec3, widths::Vec3; uniforms...)
#     robj = construct_quad(position, widths; uniforms...)
#     MoveableQuad(position, 0f0, widths, robj)
# end
#
# Base.convert(::Type{Hazel.RenderObject}, q::MoveableQuad) = q.robj
#
# # TODO
# # only call this on rotation
# function recalculate!(q::MoveableQuad)
#     q.robj.uniforms["u_transform"] = Hazel.translationmatrix(q.position) *
#                                      Hazel.rotationmatrix_z(q.rotation) *
#                                      Hazel.scalematrix(q.scale)
#     nothing
# end
# Hazel.moveto!(q::MoveableQuad, p::Vec3f0) = (q.position = p; recalculate!(q))
# Hazel.moveto!(q::MoveableQuad, p::Vec2f0) = moveto!(q, Vec3f0(p..., q.position[3]))
# Hazel.moveby!(q::MoveableQuad, v::Vec3f0) = moveto!(q, q.position + v)
# Hazel.moveby!(q::MoveableQuad, v::Vec2f0) = moveto!(q, q.position + Vec3f0(v..., 0))
#
# Hazel.rotateto!(q::MoveableQuad, θ::Float32) = (q.rotation = θ; recalculate!(q))
# Hazel.rotateby!(q::MoveableQuad, θ::Float32) = rotateto!(q, q.rotation + θ)
#
# scaleto!(q::MoveableQuad, s::Vec3f0) = (q.scale = s; recalculate!(q))
# scaleto!(q::MoveableQuad, s::Vec2f0) = scaleto!(q, Vec3f0(s..., 1.0))
# scaleto!(q::MoveableQuad, s::Float32) = scaleto!(q, Vec3f0(s, s, 1.0))
# scaleby!(q::MoveableQuad, s::Vec3f0) = scaleto!(q, s .* q.scale)
# scaleby!(q::MoveableQuad, s::Vec2f0) = scaleby!(q, Vec3f0(s..., 1.0))
# scaleby!(q::MoveableQuad, s::Float32) = scaleto!(q, s * q.scale)
# # TODO move these general methods into Hazel
# Hazel.rotateto!(q, θ::Real) = rotateto!(q, Float32(θ))
# Hazel.rotateby!(q, θ::Real) = rotateby!(q, Float32(θ))
# scaleto!(q, s::Real) = scaleto!(q, Float32(s))
# scaleby!(q, s::Real) = scaleby!(q, Float32(s))
# # TODO move this definition to Hazel somewhere
# export scaleto!, scaleby!
#
# """
#     Quad(position, widths; uniforms...)
#
# Constructs a RenderObject which represents an unmoveable quad.
#
# See also: [`MoveableQuad`](@ref)
# """
# function Quad(position::Vec2, widths::Vec2; uniforms...)
#     Quad(Vec3f0(position..., 0), Vec3f0(widths..., 0); uniforms...)
# end
# function Quad(position::Vec3, widths::Vec3; uniforms...)
#     construct_quad(position, widths; uniforms...)
# end
#
# @HZ_profile function construct_quad(p::Vec3f0, w::Vec3f0; kwargs...)
#     # TODO Should this really always be a scaled square?
#     vertices = Float32[0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0, 1, 1, 1, 1, 1]
#     layout = Hazel.BufferLayout(position = Point2f0, uv = Point2f0)
#     vertex_buffer = Hazel.VertexBuffer(vertices, layout)
#     index_buffer = Hazel.IndexBuffer(UInt32[0, 1, 2, 1, 2, 3])
#
#     # TODO Only generate necessary uniforms
#     # i.e. no tilingfactor if texture is not given
#     defaults = Dict{String, Any}(
#         "u_color" => Vec4f0(1),
#         "u_texture" => Hazel.Texture2D(fill(RGBA(1, 1, 1, 1), 1, 1)),
#         "u_tilingfactor" => 1f0,
#         "u_transform" => Hazel.translationmatrix(p) * Hazel.scalematrix(w)
#     )
#     uniforms = merge(
#         defaults,
#         Dict{String, Any}(Pair(string(k), v) for (k, v) in kwargs)
#     )
#
#     shader = Hazel.Shader(joinpath(Hazel.assetpath, "shaders", "texture.glsl"))
#
#     Hazel.RenderObject(
#         shader,
#         Hazel.VertexArray(vertex_buffer, index_buffer),
#         uniforms
#     )
# end