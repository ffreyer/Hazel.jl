abstract type AbstractVertexArray <: AbstractGPUObject end

# VertexArray
"""
    vertex_buffer(vertex_array)

Returns all vertex buffers connected to the given `vertex_array`.
"""
@backend vertex_buffer

"""
    index_buffer(vertex_array)

Returns the index buffer connected to the given `vertex_array`.
"""
@backend index_buffer
