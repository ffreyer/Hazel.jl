struct BinarySerialization end
struct TextSerialization end



################################################################################
### Serialize
################################################################################



# Scene Serialization
serialize(filepath, scene) = serialize(filepath, scene, TextSerialization())
function serialize(filepath, scene::Scene, ::TextSerialization)
    serialized_entities = map(serialize, Overseer.valid_entities(scene))

    output = Dict(
        "Scene" => "Unnamed Scene",
        "Entities" => serialized_entities
    )

    YAML.write_file(filepath, output)
end
function serialize(filepath, scene::Scene, ::BinarySerialization)
    @assert false "Not implemented"
    return false
end


# Component Serialization
serialize(c::NameComponent) = "NameComponent" => Dict("name" => string(c))
serialize(c::SimpleTexture) = "SimpleTexture" => Dict("path" => c.texture.path)
serialize(c::ColorComponent) = "Color" => Dict("color" => c.color)
function serialize(c::Transform)
    "Transform" => Dict(
        "translation" => c.translation,
        "rotation" => c.rotation,
        "scale" => c.scale
    )
end
serialize(c::IsVisible) = "IsVisible" => Dict("visible" => c.val)
serialize(c::TilingFactor) = "Tiling Factor" => Dict("tiling factor" => c.tf)
function serialize(c::InstancedQuad)
    "Instanced Quad" => Dict(
        "visible" => c.visible,
        "color" => c.color,
        "texture path" => c.texture.path,
        "uv" => c.uv,
        "tiling factor" => c.tilingfactor,
    )
end
function serialize(c::CameraComponent)
    "Camera" => Dict(
        "aspect" => c.aspect,
        "height" => c.height,
        "orthographic near" => c.o_near,
        "orthographic far" => c.o_far,
        "fov" => c.fov,
        "perspective near" => c.p_near,
        "perspective far" => c.p_far,
        "projection type" => c.projection_type,
        "fix aspect ratio" => c.fix_aspect_ratio,
        "active" => c.active
    )
end
function serialize(c::T) where T
    @debug "Failed to serialize $T"
    nothing
end


# Entity Serialization
function serialize(e::Entity)
    output = Dict(
        "Entity" => string(uuid4()), 
        filter(x -> x !== nothing, map(serialize, e))...
    )
end



################################################################################
### Deserialize
################################################################################


function deserialize_entity(scene, data, texture_library)
    uuid = data["Entity"]
    
    name = NameComponent(data["NameComponent"]["name"])
    transform =  Transform(
        Vec3f0(data["Transform"]["translation"]),
        Vec3f0(data["Transform"]["rotation"]),
        Vec3f0(data["Transform"]["scale"])
    )
    components = Any[name, transform]

    if haskey(data, "Instanced Quad")
        current = data["Instanced Quad"]
        texture_path = current["texture path"]
        texture = if texture_path == ""
            blank_texture(scene)
        else
            if haskey(texture_library, texture_path)
                texture_library[texture_path]
            else
                t = Texture2D(texture_path)
                texture_library[texture_path] = t
                t
            end
        end

        push!(components, InstancedQuad(
            transform, texture, 
            # TODO: This is what we call a security flaw :^)
            uv = eval(Meta.parse(current["uv"])), 
            visible = current["visible"],
            tilingfactor = Float32(current["tiling factor"]), 
            color = Vec4f0(current["color"])
        ))
    end

    if haskey(data, "Camera")
        current = data["Camera"]
        push!(components, CameraComponent(
            height = Float32(current["height"]),
            aspect = Float32(current["aspect"]),
            o_near = Float32(current["orthographic near"]),
            o_far = Float32(current["orthographic far"]),
            fov = Float32(current["fov"]),
            p_near = Float32(current["perspective near"]),
            p_far = Float32(current["perspective far"]),
            projection_type = eval(Meta.parse(current["projection type"])), # TODO
            fix_aspect_ratio = current["fix aspect ratio"],
            active = current["active"]
        ))
    end

    Entity(scene, components...)
end
deserialize(filepath) = deserialize(filepath, TextSerialization())
function deserialize(filepath, ::TextSerialization)
    data = YAML.load_file(filepath)
    if !haskey(data, "Scene")
        return false
    end

    name = data["Scene"]
    scene = Scene()

    if haskey(data, "Entities")
        texture_library = Dict{String, Texture2D}()
        map(data["Entities"]) do e
            deserialize_entity(scene, e, texture_library)
        end
    end

    return scene
end
function deserialize(filepath, ::BinarySerialization)
    @assert false "Not implemented"
    return false
end



################################################################################
### YAML Extensions
################################################################################



function YAML._print(io::IO, arr::StaticArray, level::Int=0, ignore_level::Bool=false)
    println(io, repeat("  ", ignore_level ? 0 : level), arr)
end

function YAML._print(io::IO, arr::Vec3f0, level::Int=0, ignore_level::Bool=false)
    seek(io, position(io)-1)
    println(io, " [", arr[1], ", ", arr[2], ", ", arr[3], "]")
end

function YAML._print(io::IO, arr::Vec4f0, level::Int=0, ignore_level::Bool=false)
    seek(io, position(io)-1)
    println(io, " [", arr[1], ", ", arr[2], ", ", arr[3], ", ", arr[4], "]")
end

function YAML._print(io::IO, arr::Point3f0, level::Int=0, ignore_level::Bool=false)
    seek(io, position(io)-1)
    println(io, " [", arr[1], ", ", arr[2], ", ", arr[3], "]")
end