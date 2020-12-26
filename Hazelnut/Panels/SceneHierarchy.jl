using CImGui
using Hazel
using Overseer
using CImGui.CSyntax.CStatic

mutable struct SceneHierarchyPanel
    scene::Scene
    selected::Hazel.Entity

    SceneHierarchyPanel(scene::Scene) = new(scene)
end

context!(p::SceneHierarchyPanel, s::Scene) = p.scene = s

@HZ_profile function render!(p::SceneHierarchyPanel)
    CImGui.Begin("Scene Hierarchy")
    reg = Hazel.registry(p.scene)
    for e in entities(reg)
        entity = Hazel.Entity(p.scene, e)
        draw_entity_node!(p, entity)
    end

    # We can't do this the way we have the struct, right?
    # if CImGui.IsMouseDown(0) && CImGui.IsWindowHovered()
    #     p.selected = nothing
    # end
    CImGui.End()

    CImGui.Begin("Properties")
    isdefined(p, :selected) && draw_components!(p.selected)
    CImGui.End()
end

function draw_entity_node!(p::SceneHierarchyPanel, entity::Hazel.Entity)
    if !haskey(entity, NameComponent)
        @warn "Skipping unnamed entity"
        return
    end
    
    flags = if isdefined(p, :selected) && (p.selected == entity)
        CImGui.ImGuiTreeNodeFlags_Selected else 0 end |
        CImGui.ImGuiTreeNodeFlags_OpenOnArrow

    opened = CImGui.TreeNodeEx(
        Ptr{Cvoid}(Hazel.RawEntity(entity).id), flags, string(entity[NameComponent])
    )

    CImGui.IsItemClicked() && (p.selected = entity)
    if opened
        CImGui.TreePop()
        opened = CImGui.TreeNodeEx(
            Ptr{Cvoid}(Hazel.RawEntity(entity).id + UInt32(1000000)), flags, "xD"
        )
        if opened
            CImGui.TreePop()
        end
    end
    nothing
end

function draw_components!(entity::Hazel.Entity)
    # TODO
    # Would be nice to have buffer and position as static things
    flags = CImGui.ImGuiTreeNodeFlags_DefaultOpen

    if haskey(entity, NameComponent)
        name = string(entity[NameComponent])
        buffer = name * "\0"^256
        if CImGui.InputText("Tag", buffer, length(buffer))
            entity[NameComponent] = NameComponent(strip(buffer, '\0'))
        end
    end

    if haskey(entity, Hazel.Transform2D)
        if CImGui.TreeNodeEx(Ptr{Cvoid}(hash(Hazel.Transform2D)), flags, "Transform 2D")
            pos = Vector(entity[Hazel.Transform2D].position)
            if CImGui.DragFloat3("Position", pos, 0.5f0)
                entity[Hazel.Transform2D] = Hazel.Transform2D(
                    entity[Hazel.Transform2D], position = Vec3f0(pos)
                )
            end
            CImGui.TreePop()
        end
    end
    nothing
end