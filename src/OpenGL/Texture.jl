struct Texture2D <: AbstractTexture
    path::String
    #img::Array{RGBA{N0f8},2}
    size::Tuple{UInt32, UInt32}
    id::UInt32
end

function Texture2D(path::String, slot = 0)
    # may be the wrong kind of flip
    formated = load(path)[1:end, end:-1:1]
    _size = UInt32.(size(formated))
    img = [UInt8(x.i) for c in formated for x in (c.r, c.g, c.b)]


    r = Ref{UInt32}()
    glGenTextures(1, r)
    id = r[]
    glBindTexture(slot, id)
    glTexStorage2D(GL_TEXTURE_2D, 1, GL_RGB8, _size[1], _size[2])
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, _size[1], _size[2], 0, GL_RGB, GL_UNSIGNED_BYTE, img)

    Texture2D(path, _size, id)
end
width(t::Texture2D) = t.size[1]
height(t::Texture2D) = t.size[2]
bind(t::Texture2D, slot=0) = glBindTexture(slot, t.id) #glBindTextureUnit
# unbind(t::Texture2D) = glBindTexture(slot, 0)
destroy(t::Texture2D) = glDeleteTextures(id)
