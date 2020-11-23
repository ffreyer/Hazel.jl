mutable struct Texture2D <: AbstractTexture
    path::String
    size::Tuple{UInt32, UInt32}
    id::UInt32
    internal_format::UInt32
    data_format::UInt32
    colortype::DataType
end

function Texture2D(path::String, slot = 0)
    # may be the wrong kind of flip
    formated = load(path)'[1:end, end:-1:1]
    Texture2D(formated, path=path)
end

@HZ_profile function Texture2D(img::Matrix{CT}; path="") where {CT <: Union{RGB, RGBA}}
    _size = UInt32.(size(img))
    if eltype(img) <: RGB
        _img = [UInt8(x.i) for c in img for x in (c.r, c.g, c.b)]
        internal_format = GL_RGB8
        data_format = GL_RGB
    elseif eltype(img) <: RGBA
        _img = [UInt8(x.i) for c in img for x in (c.r, c.g, c.b, c.alpha)]
        internal_format = GL_RGBA8
        data_format = GL_RGBA
    else
        throw(ErrorException("Image color data format $(eltype(img)) not implemented."))
    end

    r = Ref{UInt32}()
    glGenTextures(1, r)
    id = r[]
    glBindTexture(GL_TEXTURE_2D, id)
    glTexStorage2D(GL_TEXTURE_2D, 1, internal_format, _size...)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)

    glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, _size..., data_format, GL_UNSIGNED_BYTE, _img)
    #glTexImage2D(GL_TEXTURE_2D, 0, type, _size..., 0, type, GL_UNSIGNED_BYTE, _img)

    finalizer(destroy, Texture2D(path, _size, id, internal_format, data_format, eltype(img)))
end

width(t::Texture2D) = t.size[1]
height(t::Texture2D) = t.size[2]
Base.size(t::Texture2D) = t.size
# TODO glActiveTexture(GL_TEXTURE1) # TODO make list
"""
    bind(texture[, slot=1])

Bind the texture to a given slot. The slot index is 1-based and must be
between 1 and 32
"""
@HZ_profile bind(t::Texture2D) = glBindTexture(GL_TEXTURE_2D, t.id)
@HZ_profile function bind(t::Texture2D, slot)
    glActiveTexture(UInt32(GL_TEXTURE0 - 1 + slot))
    # @info Int(33983 + slot-GL_TEXTURE0), t.path
    glBindTexture(GL_TEXTURE_2D, t.id)
    glActiveTexture(GL_TEXTURE0)
end
@HZ_profile unbind(t::Texture2D) = glBindTexture(GL_TEXTURE_2D, 0) #glBindTextureUnit
destroy(t::Texture2D) = glDeleteTextures(1, Ref(t.id))

img2bytes(img::Matrix{RGBA}) = [UInt8(x.i) for c in img for x in (c.r, c.g, c.b, c.alpha)]
img2bytes(img::Matrix{RGB}) = [UInt8(x.i) for c in img for x in (c.r, c.g, c.b)]

@HZ_profile function upload(t::Texture2D, img::Matrix{CT}) where {CT <: Colorant}
    t.size != size(img) && throw(DimensionMismatch("Image and Texture have different size!"))
    t.colortype != CT && throw(ErrorException("Expected colortype $(t.colortype) but got $CT."))
    bind(t)
    glTexSubImage2D(
        GL_TEXTURE_2D, 0,
        0, 0, t.size...,
        t.data_format, GL_UNSIGNED_BYTE,
        img2bytes(img)
    )
end

Base.:(==)(t1::Texture2D, t2::Texture2D) = t1.id == t2.id
# For compatability with SubTextures
uv(::Texture2D) = LRBT{Float32}(0, 1, 0, 1)
id(t::Texture2D) = t.id