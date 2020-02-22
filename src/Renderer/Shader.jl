abstract type AbstractShader <: AbstractGPUObject end

"""
    upload!(shader, name = object)
    upload!(shader, name, object)

Uploads an `object` to a uniform `name` in the given `shader`. The shader must
be bound for this.
"""
@backend upload!
