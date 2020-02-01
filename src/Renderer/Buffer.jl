# TODO unify with Shader?
# maybe AbstractGPUObject?

# Contains:
# - VertexBuffer, IndexBuffer Interface and docs
# - BufferLayout implementation

abstract type AbstractGPUBuffer <: AbstractGPUObject end
abstract type AbstractVertexBuffer <: AbstractGPUBuffer end
abstract type AbstractIndexBuffer <: AbstractGPUBuffer end
abstract type BufferLayout end


################################################################################
### VertexBuffer Interface & docstrings
################################################################################


"""
    getlayout(vertex_buffer)

Returns the layout attached to the given `vertex_buffer`
"""
@backend getlayout


################################################################################
### IndexBuffer Interface & docstrings
################################################################################


# IndexBuffer()


################################################################################
### VertexBufferLayouts
################################################################################


# TODO
# keep track of existing BufferLayouts and reuse them when possible
# Make a global ... Set? containing the "Types" of LazyBufferLayout
# how to handle id? maybe do set up another wrapper type?

"""
    Normalize{T[, should_be_normalized=true]}

Used in conjunction with `BufferLayout`. A type `T` wrapped in `Normalized{T}`
will be normalized on the GPU.
"""
struct Normalize{T, should} end
Normalize(T::DataType, normalize=true) = Normalize{T, normalize}

type(::Type{NT}) where {T, NT <: Normalize{T}} = T
Base.sizeof(::Type{NT}) where {NT <: Normalize} = sizeof(type(NT))
Base.length(::Type{NT}) where {NT <: Normalize} = length(type(NT))
Base.eltype(::Type{NT}) where {NT <: Normalize} = eltype(type(NT))
normalized(::Type{NT}) where {T, NT <: Normalize{T, true}} = true
normalized(::Type{NT}) where {T, NT <: Normalize{T, false}} = false
normalized(::Type{NT}) where {NT <: Normalize} = true

# TODO: I shouldn't, should I?
Base.length(::Type{<: Real}) = 1
Base.length(::Type{<: Complex}) = 2

struct BufferLayoutElement{BL <: BufferLayout}
    layout::BL
    index::Int64
end

"""
    LazyBufferLayout(; kwargs...)
    LazyBufferLayout(pairs::Pair{Symbol, DataType}...)
    LazyBufferLayout(pairs::Pair{Any, DataType}...)

A LazyBufferLayout specifies how a buffer should be interpreted by the GPU. It
is constructed using pairs (keyword arguments) of names and Types, e.g.

    LazyBufferLayout(position = Point3f0, color = RGBA{Float32})
    LazyBufferLayout(:position => Point3f0, :normal => Vec3f0)
    LazyBufferLayout("pos" => Point3f0, "color" = Normalize(NTuple{3, UInt8}))

Any type wrapped in `Normalize` will be normalized on the GPU.
"""
struct LazyBufferLayout{Types, N} <: BufferLayout
    names::NTuple{N, Symbol}
    offsets::NTuple{N, Int64}
    id::Ref{UInt32}
end

function LazyBufferLayout(pairs::Pair{Symbol, DataType}...)
    offsets = cumsum([0, (pairs[1:end-1] .|> last .|> sizeof)...])
    types = map(T -> T <: Normalize ? T : Normalize{T, false}, last.(pairs))
    LazyBufferLayout{Tuple{types...}, length(pairs)}(
        tuple(first.(pairs)...),
        tuple(offsets...),
        Ref{UInt32}()
    )
end
function LazyBufferLayout(pairs::Pair...)
    concrete_pairs = Vector{Pair{Symbol, DataType}}(undef, length(pairs))
    for (i, pair) in enumerate(pairs)
        k = first(pair) isa Symbol ? first(pair) : Symbol(first(Pair))
        if (last(pair) <: Normalize) && (last(pair) isa UnionAll)
            v = last(pair){true}
        else
            v = last(pair)
        end
        concrete_pairs[i] = k => v
    end
    LazyBufferLayout(concrete_pairs...)
end
LazyBufferLayout(; kwargs...) = LazyBufferLayout(kwargs...)
BufferLayout(args...; kwargs...) = LazyBufferLayout(args...; kwargs...)

Base.names(bl::LazyBufferLayout) = bl.names
Base.length(::LazyBufferLayout{T, N}) where {T, N} = N
Base.sizeof(::LazyBufferLayout{T}) where {T} = sum(sizeof.(T.types))
Base.getindex(bl::LazyBufferLayout, index::Int64) = BufferLayoutElement(bl, index)
Base.lastindex(bl::LazyBufferLayout) = length(bl)
Base.first(bl::LazyBufferLayout) = BufferLayoutElement(bl, 1)
Base.last(bl::LazyBufferLayout) = BufferLayoutElement(bl, length(bl))
Base.iterate(bl::LazyBufferLayout) = (first(bl), 1)
function Base.iterate(bl::LazyBufferLayout, index)
    index < length(bl) ? (bl[index+1], index+1) : nothing
end
# Base.eltype(bl::LazyBufferLayout) = BufferLayoutElement{LazyBufferLayout}
offsets(bl::LazyBufferLayout) = bl.offsets
types(bl::LazyBufferLayout{T}) where {T} = T

name(e::BufferLayoutElement{<: LazyBufferLayout}) = e.layout.names[e.index]
offset(e::BufferLayoutElement{<: LazyBufferLayout}) = e.layout.offsets[e.index]
type(e::BufferLayoutElement{LB}) where {T, LB <: LazyBufferLayout{T}} = type(T.types[e.index])
Base.length(e::BufferLayoutElement) = length(type(e))
Base.sizeof(e::BufferLayoutElement) = sizeof(type(e))
Base.eltype(e::BufferLayoutElement) = eltype(type(e))
elsizeof(e::BufferLayoutElement) = sizeof(eltype(e))
normalized(e::BufferLayoutElement{LB}) where {T, LB <: LazyBufferLayout{T}} = normalized(T.types[e.index])

# Pretty Printing
# TODO clean this up, probably

function Base.show(io::IO, bl::LazyBufferLayout)
    print(io, "LazyBufferLayout(")
    # I think I want the stripped name here (no module)
    join(io, names(bl), ", ")
    print(io, ")")
end
function Base.show(io::IO, ::MIME"text/plain", bl::LazyBufferLayout)
    print(io, "LazyBufferLayout")
    for (i, element) in enumerate(bl)
        print(io, "\n\t[", i-1, "] ")
        print(io, name(element) , " ")
        print(io, "(", length(element), " Elements, ")
        print(io, sizeof(element), " Bytes) ")
        print(io, " @ ", offset(element), "Bytes")
        print(io, " (", normalized(element) ? "normalized" : "unnormalized", ")")
    end
end
