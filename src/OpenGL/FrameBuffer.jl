
mutable struct Framebuffer <: AbstractGPUObject
    fb_id::UInt32
    t_id::UInt32
    d_id::UInt32
    size::Tuple{UInt32, UInt32}
    swap_chain_target::Bool
end

function Framebuffer(width=800, height=600)
    r = Ref{UInt32}()
    glGenFramebuffers(1, r)
    fb_id = r[]
    glBindFramebuffer(GL_FRAMEBUFFER, fb_id)

    # Colorbuffer
    r = Ref{UInt32}()
    glGenTextures(1, r)
    t_id = r[]
    glBindTexture(GL_TEXTURE_2D, t_id)
    glTexImage2D(
        GL_TEXTURE_2D, 0, GL_RGBA8, width, height, 0, 
        GL_RGBA, GL_UNSIGNED_BYTE, C_NULL
    )
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)

    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, t_id, 0)

    # depth buffer
    r = Ref{UInt32}()
    glGenTextures(1, r)
    d_id = r[]
    glBindTexture(GL_TEXTURE_2D, d_id)
    glTexImage2D(
        GL_TEXTURE_2D, 0, GL_DEPTH24_STENCIL8, width, height, 0,
        GL_DEPTH_STENCIL, GL_UNSIGNED_INT_24_8, C_NULL
    )
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_STENCIL_ATTACHMENT, GL_TEXTURE_2D, d_id, 0)

    glBindFramebuffer(GL_FRAMEBUFFER, 0)
    # @assert glFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE

    finalizer(destroy, Framebuffer(fb_id, t_id, d_id, (width, height), false))
end

destroy(fb::Framebuffer) = glDeleteFramebuffers(1, fb.fb_id)
bind(fb::Framebuffer) = glBindFramebuffer(GL_FRAMEBUFFER, fb.fb_id)
unbind(::Framebuffer) = glBindFramebuffer(GL_FRAMEBUFFER, 0)
Base.size(fb::Framebuffer) = fb.size

color_attachment(fb::Framebuffer) = fb.t_id 