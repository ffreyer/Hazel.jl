"""
    LRBT{T}(left, right, bottom, top)

Creates a `left, right, bottom, top` box.

You can unpack an `lrbt` via `l, r, b, t = lrbt`.
"""
struct LRBT{T}
    l::T
    r::T
    b::T
    t::T
end

LRBT(v::Vector) = LRBT(v...)
LRBT(t::NTuple{4}) = LRBT(t...)
LRBT(v::Vec{4}) = LRBT(v...)
LRBT(lrbt::LRBT) = lrbt

Base.iterate(lrbt::LRBT, i=1) = iterate((lrbt.l, lrbt.r, lrbt.b, lrbt.t), i)
Base.length(::LRBT) = 4
Base.eltype(::LRBT{T}) where {T} = T
Base.:(+)(lrbt::LRBT, r) = LRBT(
    lrbt.l + r[1], lrbt.r + r[1], lrbt.b + r[2], lrbt.t + r[2]
)


# transformations
"""
    moveto!(object, position)

Move an `object` to a given `postion`.
"""
@inline moveto!(x, p) = moveto!(x, Vec{length(p)}(p))
@inline moveto!(x, p::Vec) = moveto!(x, Vec{length(p), Float32}(p))
"""
    moveby!(object, Δr)

Move an `object` by a translation vector `Δr`.
"""
@inline moveby!(x, v) = moveby!(x, Vec{length(v)}(v))
@inline moveby!(x, v::Vec) = moveby!(x, Vec{length(v), Float32}(v))
@inline moveby!(x, v::Vec2f0) = moveby!(x, Vec3f0(v..., 0))
"""
    rotateto!(object, θ)

Rotates an `object` to a certain angle `θ`. (Currently 2D only)
"""
@inline rotateto!(x, θ) = rotateto!(x, Float32(θ))
"""
    rotateby!(object, Δθ)

Rotates an `object` by some angle `Δθ`. (Currently 2D only)
"""
@inline rotateby!(x, θ) = rotateby!(x, Float32(θ))
"""
    scaleto!(object, size)

Scales an `object` to a given `size`.
"""
@inline scaleto!(x, s) = scaleto!(x, Vec{length(s)}(s))
@inline scaleto!(x, s::Real) = scaleto!(x, Vec{3, Float32}(s))
@inline scaleto!(x, s::Vec) = scaleto!(x, Vec{length(s), Float32}(s))
"""
    scaleby!(object, scale)

Scales an `object` by a given `scale`.
"""
@inline scaleby!(x, s) = scaleby!(x, Vec{length(s)}(s))
@inline scaleby!(x, s::Real) = scaleby!(x, Vec{3, Float32}(s))
@inline scaleby!(x, s::Vec) = scaleby!(x, Vec{length(s), Float32}(s))



################################################################################


struct Timestep
    t::Float64
    dt::Float32
end

"""
    Timestep()
    Timestep(time_step)

Creates a `Timestep` object which holds the current time (as of creation) and
the time difference to the last time_step.
"""
Timestep() = Timestep(Float32(time()), NaN32)
function Timestep(ts::Timestep)
    t = time()
    Timestep(t, Float32(t - ts.t))
end
current(t::Timestep) = t.t
Base.time(t::Timestep) = t.t
Base.step(t::Timestep) = t.dt
delta(t::Timestep) = t.dt