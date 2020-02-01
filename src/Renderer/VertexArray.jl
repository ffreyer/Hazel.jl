abstract type AbstractVertexArray <: AbstractGPUObject end

# TODO
# This will be changed soon
@warn "Update VertexArray once you rework it"


"""
    push!(vertex_array, vertex_buffer)

Adds the given `vertex_buffer` to the given `vertex_array`
"""
@backend Base.push!(::AbstractVertexArray, ::AbstractVertexBuffer)

"""
    set!(vertex_array, index_buffer)

Sets the `index_buffer` of the given `vertex_array`.
"""
@backend set!
