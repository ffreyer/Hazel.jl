struct Texture2D <: AbstractTexture
    path::String
    size::Tuple{UInt32, UInt32}
    id::UInt32
end

function Texture2D(path::String, slot = 0)
    # may be the wrong kind of flip
    formated = load(path)'[1:end, end:-1:1]
    _size = UInt32.(size(formated))
    if eltype(formated) <: RGB
        img = [UInt8(x.i) for c in formated for x in (c.r, c.g, c.b)]
        bytetype = GL_RGB8
        type = GL_RGB
    elseif eltype(formated) <: RGBA
        img = [UInt8(x.i) for c in formated for x in (c.r, c.g, c.b, c.alpha)]
        bytetype = GL_RGBA8
        type = GL_RGBA
    else
        throw(ErrorException("Image color data format $(eltype(formated)) not implemented."))
    end

    r = Ref{UInt32}()
    glGenTextures(1, r)
    id = r[]
    glBindTexture(GL_TEXTURE_2D, id)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)
    glTexImage2D(GL_TEXTURE_2D, 0, type, _size..., 0, type, GL_UNSIGNED_BYTE, img)

    Texture2D(path, _size, id)
end
width(t::Texture2D) = t.size[1]
height(t::Texture2D) = t.size[2]
bind(t::Texture2D) = glBindTexture(GL_TEXTURE_2D, t.id) #glBindTextureUnit
unbind(t::Texture2D) = glBindTexture(GL_TEXTURE_2D, 0) #glBindTextureUnit
destroy(t::Texture2D) = glDeleteTextures(id)
