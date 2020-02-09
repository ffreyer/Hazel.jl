# Add when needed
gltype(::Type{<: Float32}) = GL_FLOAT
gltype(::Type{<: Int32}) = GL_FLOAT
gltype(::Type{<: Bool}) = GL_Bool
gltype(::Type{<: Point2f0}) = GL_FLOAT_VEC2
gltype(::Type{<: Point3f0}) = GL_FLOAT_VEC3
gltype(::Type{<: Point4f0}) = GL_FLOAT_VEC4
gltype(::Type{<: Vec2f0}) = GL_FLOAT_VEC2
gltype(::Type{<: Vec3f0}) = GL_FLOAT_VEC3
gltype(::Type{<: Vec4f0}) = GL_FLOAT_VEC4
gltype(::Type{<: NTuple{2, Float32}}) = GL_FLOAT_VEC2
gltype(::Type{<: NTuple{3, Float32}}) = GL_FLOAT_VEC3
gltype(::Type{<: NTuple{4, Float32}}) = GL_FLOAT_VEC4
gltype(::Type{<: Mat2f0}) = GL_FLOAT_Mat2
gltype(::Type{<: Mat3f0}) = GL_FLOAT_Mat3
gltype(::Type{<: Mat4f0}) = GL_FLOAT_Mat4
gltype(x::Bool) = x ? GL_TRUE : GL_FALSE