using CImGui
using Hazel
using Overseer

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