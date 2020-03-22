struct Shader <: AbstractShader
    id::Ref{UInt32}
end

_opengl_string(s::Vector{UInt8}) = Ptr{UInt8}[pointer(s)]
_opengl_string(s::String) = _opengl_string(Vector{UInt8}(s))


"""
    Shader(vertex_source, fragment_source)

Constructs a Shader from strings containing their source code.

# Warning

There is explicit cleanup required! Call ´destroy(shader)´ to remove it
from the gpu.
"""
function Shader(vertex_source::String, fragment_source::String)
    # TODO should this hard-error when it fails?
    # TODO should this return a FailedShader or DefaultShader when it fails?
    # Based on https://www.khronos.org/opengl/wiki/Shader_Compilation#Example

    # Create an empty vertex shader handle
    vertex_shader = glCreateShader(GL_VERTEX_SHADER)

    # Send the vertex shader source code to GL
    glShaderSource(
        vertex_shader,
        1,
        _opengl_string(vertex_source),
        Ref{Int32}(length(vertex_source))
    )

    # Compile the vertex shader
    glCompileShader(vertex_shader)

    is_compiled = Ref{GLint}(0)
    glGetShaderiv(vertex_shader, GL_COMPILE_STATUS, is_compiled)
    if is_compiled == GL_FALSE
    	max_length = Ref{GLint}(0)
    	glGetShaderiv(vertex_shader, GL_INFO_LOG_LENGTH, max_length)

    	# The maxLength includes the NULL character
        info_log = Vector{Cchar}(undef, max_length)
    	glGetShaderInfoLog(vertex_shader, max_length[], max_length, info_log)

    	# We don't need the shader anymore.
    	glDeleteShader(vertex_shader);

    	# Use the infoLog as you see fit.
        @error "Vertex Shader Compilation failed - Info Log: \n$info_log"

    	# In this simple program, we'll just leave
    	return nothing
    end

    # Create an empty fragment shader handle
    fragment_shader = glCreateShader(GL_FRAGMENT_SHADER)

    # Send the fragment shader source code to GL
    glShaderSource(
        fragment_shader,
        1,
        _opengl_string(fragment_source),
        Ref{Int32}(length(fragment_source))
    )

    # Compile the fragment shader
    glCompileShader(fragment_shader)

    glGetShaderiv(fragment_shader, GL_COMPILE_STATUS, is_compiled)
    if is_compiled == GL_FALSE
    	max_length = Ref{GLint}(0)
    	glGetShaderiv(fragment_shader, GL_INFO_LOG_LENGTH, max_length)

    	# The maxLength includes the NULL character
    	info_log = Vector{Cchar}(undef, max_length)
    	glGetShaderInfoLog(fragment_shader, max_length[], max_length, info_log)

    	# We don't need the shader anymore.
    	glDeleteShader(fragment_shader)
    	# Either of them. Don't leak shaders.
    	glDeleteShader(vertex_shader)

    	# Use the infoLog as you see fit.
        @error "Fragment Shader Compilation failed - Info Log: \n$info_log"

    	# In this simple program, we'll just leave
    	return nothing
    end

    # Vertex and fragment shaders are successfully compiled.
    # Now time to link them together into a program.
    # Get a program object.
    program = glCreateProgram()

    # Attach our shaders to our program
    glAttachShader(program, vertex_shader)
    glAttachShader(program, fragment_shader)

    # Link our program
    glLinkProgram(program)

    # Note the different functions here: glGetProgram* instead of glGetShader*.
    is_linked = is_compiled # Reusing it
    glGetProgramiv(program, GL_LINK_STATUS, is_linked)
    if is_linked == GL_FALSE
    	max_length = Ref{GLint}(0)
    	glGetProgramiv(program, GL_INFO_LOG_LENGTH, max_length)

    	# The maxLength includes the NULL character
    	info_log = Vector{Cchar}(max_length)
    	glGetProgramInfoLog(program, max_length[], max_length, info_log)

    	# We don't need the program anymore.
    	glDeleteProgram(program)
    	# Don't leak shaders either.
    	glDeleteShader(vertex_shader)
    	glDeleteShader(fragment_shader)

    	# Use the infoLog as you see fit.
        @error "Program Linking failed - Info Log: \n$info_log"

    	# In this simple program, we'll just leave
    	return nothing
    end

    # Always detach shaders after a successful link.
    glDetachShader(program, vertex_shader)
    glDetachShader(program, fragment_shader)

    return Shader(program)
end

destroy(shader::Shader) = glDeleteProgram(shader.id[])
bind(shader::Shader) = glUseProgram(shader.id[])
unbind(shader::Shader) = glUseProgram(0)


function upload!(shader::Shader; kwargs...)
    for (k, v) in kwargs
        upload!(shader, k, v)
    end
end
upload!(shader::Shader, name::Symbol, v) = upload!(shader, string(name), v)
function upload!(shader::Shader, name::String, v)
    location = glGetUniformLocation(shader.id[], name)
    location == -1 && throw(ErrorException("$name is not a valid uniform name!"))
    _upload!(shader, location, v)
end
function _upload!(shader::Shader, location, matrix::Mat4f0)
    glUniformMatrix4fv(location, 1, GL_FALSE, matrix)
end
function _upload!(shader::Shader, location, vec::Vec4f0)
    glUniform4f(location, vec...)
end
