mutable struct Shader <: AbstractShader
    id::UInt32
    name::String
end

_opengl_string(s::Vector{UInt8}) = Ptr{UInt8}[pointer(s)]
_opengl_string(s::String) = _opengl_string(Vector{UInt8}(s))
_name_from_file(path::String) = string(split(splitdir(path)[2], '.')[1])

"""
    Shader(path_to_file)

Constructs a Shader from a file containing their source code. Within the file
`#type <shadertype>`, where shadertype is either `vertex` or `fragment`, should
be used to mark the type of shader.

# Warning

There is explicit cleanup required! Call ´destroy(shader)´ to remove it
from the gpu.
"""
@HZ_profile function Shader(path::String; debug=false, name=_name_from_file(path))
    sources = Pair{UInt32, String}[]
    open(path, "r") do file
        source = ""
        target = :none
        for line in eachline(file)
            if startswith(line, "#type")
                target == :vertex && push!(sources, GL_VERTEX_SHADER => source)
                target == :fragment && push!(
                    sources, GL_FRAGMENT_SHADER => source
                )
                if (target == :none) && !isempty(source)
                    @warn "Failed to parse '$source' - no target set."
                end
                source = ""

                maybe_target = line[7:end]
                if occursin(maybe_target, "vertex")
                    target = :vertex
                elseif occursin(maybe_target, "fragment")
                    target = :fragment
                else
                    target = :none
                    @warn "Failed to parse '$line'"
                end
                continue
            end
            isempty(line) && continue
            startswith(line, "//") && continue
            source *= line * "\n"
        end

        target == :vertex && push!(sources, GL_VERTEX_SHADER => source)
        target == :fragment && push!(
            sources, GL_FRAGMENT_SHADER => source
        )
        if (target == :none) && !isempty(source)
            @warn "Failed to parse '$source' - no target set."
        end
    end

    if debug
        for (target, source) in sources
            println("----------------------------")
            println("target is $target")
            println(source)
        end
        println("----------------------------")
    end

    compile(sources, name=name)
end


"""
    Shader(vertex_source, fragment_source)

Constructs a Shader from strings containing their source code.

# Warning

There is explicit cleanup required! Call ´destroy(shader)´ to remove it
from the gpu.
"""
function Shader(name::String, vertex_source::String, fragment_source::String)
    compile([
        GL_VERTEX_SHADER => vertex_source,
        GL_FRAGMENT_SHADER => fragment_source
    ], name=name)
end

function compile(sources::Vector{Pair{UInt32, String}}; name::String)
    # TODO should this hard-error when it fails?
    # TODO should this return a FailedShader or DefaultShader when it fails?
    # Based on https://www.khronos.org/opengl/wiki/Shader_Compilation#Example

    program = glCreateProgram()
    gl_shader_ids = Vector{UInt32}(undef, length(sources))

    for (i, (type, source)) in enumerate(sources)
        shader = glCreateShader(type)

        glShaderSource(
            shader,
            1,
            _opengl_string(source),
            Ref{Int32}(length(source))
        )

        glCompileShader(shader)

        is_compiled = Ref{GLint}(0)
        glGetShaderiv(shader, GL_COMPILE_STATUS, is_compiled)
        if is_compiled == GL_FALSE
        	max_length = Ref{GLint}(0)
        	glGetShaderiv(shader, GL_INFO_LOG_LENGTH, max_length)
            info_log = Vector{Cchar}(undef, max_length)
        	glGetShaderInfoLog(shader, max_length[], max_length, info_log)
        	glDeleteShader(shader);
            @error "Shader Compilation failed - Info Log: \n$info_log"
            break
        end

        glAttachShader(program, shader)
        gl_shader_ids[i] = shader
    end

    glLinkProgram(program)

    is_linked = Ref{GLint}(0)
    glGetProgramiv(program, GL_LINK_STATUS, is_linked)
    if is_linked == GL_FALSE
    	max_length = Ref{GLint}(0)
    	glGetProgramiv(program, GL_INFO_LOG_LENGTH, max_length)

    	info_log = Vector{Cchar}(max_length)
    	glGetProgramInfoLog(program, max_length[], max_length, info_log)

    	glDeleteProgram(program)
    	glDeleteShader.(gl_shader_ids)

        @error "Program Linking failed - Info Log: \n$info_log"

    	return nothing
    end

    for shader in gl_shader_ids
        glDetachShader(program, shader)
    end

    return finalizer(destroy, Shader(program[], name))
end

destroy(shader::Shader) = glDeleteProgram(shader.id)
@HZ_profile bind(shader::Shader) = glUseProgram(shader.id)
@HZ_profile unbind(shader::Shader) = glUseProgram(0)
name(shader::Shader) = shader.name


"""
    upload!(shader, name = object)
    upload!(shader, name, object)

Uploads an `object` to a uniform `name` in the given `shader`. The shader must
be bound for this.
"""
function upload!(shader::Shader; kwargs...)
    for (k, v) in kwargs
        upload!(shader, k, v)
    end
end
upload!(shader::Shader, name::Symbol, v) = upload!(shader, string(name), v)
@HZ_profile function upload!(shader::Shader, name::String, v)
    location = glGetUniformLocation(shader.id, name)
    location == -1 && throw(ErrorException("$name is not a valid uniform name!"))
    _upload!(shader, location, v)
end

# Mappings to OpenGL functions
for (type, typename) in (Float32 => :f, Int32 => :i, UInt32 => :ui)
    @eval @HZ_profile function _upload!(shader::Shader, location, v::$type)
        $(Symbol(:glUniform1, typename))(location, v)
    end
    @eval @HZ_profile function _upload!(shader::Shader, location, v::Vector{$type})
        $(Symbol(:glUniform1, typename, :v))(location, UInt32(length(v)), v)
    end
end

for N in 2:4
    for (type, typename) in (Float32 => :f, Int32 => :i)
        # Vec{1..4, Int32/Float32} conversions
        @eval @HZ_profile function _upload!(shader::Shader, location, vec::Vec{$N, $type})
            $(Symbol(:glUniform, N, typename))(location, vec...)
        end
    end
    for M in 2:4
        # Matrices
        @eval @HZ_profile function _upload!(shader::Shader, location,
                matrix::SMatrix{$N, $M, Float32, $(N*M)}
            )
            $(Symbol(:glUniformMatrix, N == M ? N : "$(N)x$(M)", :fv))(
                location, 1, GL_FALSE, matrix
            )
        end
    end
end

# Texture:
# (target, texture)
@HZ_profile function _upload!(shader::Shader, location, t::AbstractTexture)
    _upload!(shader, location, (UInt32(0), t))
end
@HZ_profile function _upload!(shader::Shader, location, t::Tuple{<:Integer, <:AbstractTexture})
    activeTarget = GL_TEXTURE0 + UInt32(t[1])
    glActiveTexture(activeTarget)
    bind(t[2])
    _upload!(shader, location, activeTarget)
end
@HZ_profile function _upload!(shader::Shader, location, t::Vector{<:AbstractTexture})
    targets = UInt32.(eachindex(t) .- 1)
    _upload!(shader, location, targets)
end



const ShaderLibrary = Dict{String, Shader}

Base.push!(sl::ShaderLibrary, shader::Shader) = push!(sl, name(shader) => shader)
@HZ_profile function load!(
        sl::ShaderLibrary, filepath::String;
        name=_name_from_file(filepath), kwargs...
    )
    if haskey(sl, name)
        sl[name] = Shader(filepath, name=name; kwargs...)
    else
        push!(sl, Shader(filepath; kwargs...))
    end
end
