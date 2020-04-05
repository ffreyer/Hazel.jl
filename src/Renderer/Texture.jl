abstract type AbstractTexture <: AbstractGPUObject end

# VertexArray
"""
    vertex_buffer(vertex_array)

Returns all vertex buffers connected to the given `vertex_array`.
"""
@backend width

"""
    index_buffer(vertex_array)

Returns the index buffer connected to the given `vertex_array`.
"""
@backend height
