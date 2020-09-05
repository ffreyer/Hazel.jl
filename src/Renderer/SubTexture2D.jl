struct SubTexture{Tex <: Texture2D, T}
    texture::Tex
    lrbt::LRBT{T}
end


"""
    SubTexture(path, i, j, dw, dh)
    SubTexture(texture, i, j, dw, dh)
    SubTexture(texture, uv::LRBT)

Creates a SubTexture which adresses a region of a larger texture. Can be 
constrcuted from either an image `path` or an existing `texture`.

  (i, j+dh) --------- (i+dw, j+dh)
           |         |
           |         |
     (i, j) --------- (i+dw, j)
"""
SubTexture(path::String, i, j, dw, dh) = SubTexture(Texture2D(path), i, j, dw, dh)
function SubTexture(texture::Texture2D, i, j, dw, dh)
    SubTexture(texture, ind2uv(i, j, dw, dh, texture))
end

function ind2uv(i, j, w, h, t::Hazel.Texture2D)
    imgw, imgh = size(t)
    l = (i-1) * w
    r = i * w
    b = (j-1) * h
    t = j * h
    LRBT{Float32}(l/imgw, r/imgw, b/imgh, t/imgh)
end

texture(t::SubTexture) = t.texture
uv(t::SubTexture) = t.lrbt



struct RegularSpriteSheet{Tex, T}
    texture::Tex
    regions::Matrix{LRBT{T}}
end

"""
    RegularSpriteSheet(path[; Nx, Ny, dw, dh])
    RegularSpriteSheet(texture[; Nx, Ny, dw, dh])

Creates a spritesheet with a regular grid from a given `texture` (or `path` to
an image). You need to either pass the number of sprite `Nx, Ny` along x- and y-
direction, or the pixel size of a sprite `dw, dh`.
"""
function RegularSpriteSheet(path::String, args...; kwargs...)
    RegularSpriteSheet(Texture2D(path), args...; kwargs...)
end
function RegularSpriteSheet(
        texture::Texture2D; 
        dw = -1, dh = -1,
        _W = width(texture), _H = height(texture), 
        Nx = div(_W, dw), Ny = div(_H, dh), 
    )
    dw == -1 && (dw = div(_W, Nx))
    dh == -1 && (dh = div(_H, Ny))
    Nx*dw != _W && @warn("Subtexture does not fit texture width ($Nx × $dw ≠ $_W)")
    Ny*dh != _H && @warn("Subtexture does not fit texture heigth ($Ny × $dh ≠ $_H)")
    regions = [ind2uv(i, j, dw, dh, texture) for i in 1:Nx, j in 1:Ny]
    RegularSpriteSheet(texture, regions)
end

_iscontinuous(::Integer) = true
_iscontinuous(::Colon) = true
_iscontinuous(::UnitRange) = true
_iscontinuous(r::StepRange) = step(r) == 1
function Base.getindex(s::RegularSpriteSheet, i, j)
    if !(_iscontinuous(i) && _iscontinuous(j))
        throw(ArgumentError("RegularSpriteSheet must be indexed continously"))
    end
    l = s.regions[minimum(i), minimum(j)].l
    r = s.regions[maximum(i), minimum(j)].r
    b = s.regions[minimum(i), minimum(j)].b
    t = s.regions[minimum(i), maximum(j)].t
    SubTexture(s.texture, LRBT{Float32}(l, r, b, t))
end
function Base.getindex(s::RegularSpriteSheet, i::Integer, j::Integer)
    SubTexture(s.texture, s.regions[i, j])
end
texture(s::RegularSpriteSheet) = s.texture
uv(::RegularSpriteSheet) = LRBT{Float32}(0, 1, 0, 1)
