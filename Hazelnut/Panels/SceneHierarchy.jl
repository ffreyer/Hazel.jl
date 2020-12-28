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

macro componentUI(component, name, code)
    esc(quote
        if haskey(entity, $component)
            if CImGui.TreeNodeEx(Ptr{Cvoid}(hash($component)), flags, $name)
                $code
                CImGui.TreePop()
            end
        end
    end)
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


    @componentUI Hazel.Transform "Transform" begin
        t = entity[Hazel.Transform]
        pos = Vector(t.translation)
        rot = Float32(360/2pi) .* Vector(t.rotation)
        scale = Vector(t.scale)
        if draw_vec3_control("Translation", pos)
            t.translation = Vec3f0(pos)
        end
        if draw_vec3_control("Rotation", rot)
            t.rotation = Float32(2pi / 360) .* Vec3f0(rot)
        end
        if draw_vec3_control("Scale", scale, 1f0)
            t.scale = Vec3f0(scale)
        end
        CImGui.TreePop()
    end

    @componentUI Hazel.CameraComponent "Transform 2D" begin
        cam = entity[Hazel.CameraComponent]

        active = Ref(cam.active)
        CImGui.Checkbox("Primary", active) && activate!(entity)

        proj_types = ("Orthographic", "Perspective")
        current = proj_types[Int(cam.projection_type)]
        if CImGui.BeginCombo("Projection", current)
            for i in eachindex(proj_types)
                selected = i == Int(cam.projection_type)
                if CImGui.Selectable(proj_types[i], selected)
                    cam.projection_type = Hazel.ProjectionType(i)
                end
                selected && CImGui.SetItemDefaultFocus()
            end
            CImGui.EndCombo()
        end

        if cam.projection_type == Hazel.Orthographic
            height = Ref(cam.height)
            CImGui.DragFloat("Height", height) && (cam.height = height[])
            near = Ref(cam.o_near)
            CImGui.DragFloat("Near clip", near) && (cam.o_near = near[])
            far = Ref(cam.o_far)
            CImGui.DragFloat("Far clip", far) && (cam.o_far = far[])
            fixed = Ref(cam.fix_aspect_ratio)
            if CImGui.Checkbox("Fixed Aspect Ratio", fixed)
                cam.fix_aspect_ratio = fixed[]
            end
        else
            fov = Ref(cam.fov)
            CImGui.DragFloat("FOV", fov) && (cam.fov = fov[])
            near = Ref(cam.p_near)
            CImGui.DragFloat("Near clip", near) && (cam.p_near = near[])
            far = Ref(cam.p_far)
            CImGui.DragFloat("Far clip", far) && (cam.p_far = far[])
        end
        CImGui.TreePop()
    end

    @componentUI Hazel.QuadVertices "Sprite Renderer" begin
        tex = entity[Hazel.SimpleTexture]
        buffer = tex.texture.path * "\0"^256
        if CImGui.InputText("Texture path", buffer, length(buffer))
            #entity[NameComponent] = NameComponent(strip(buffer, '\0'))
        end
        color = Vector(entity[Hazel.ColorComponent].color)
        if CImGui.ColorEdit4("Color", color)
            entity[Hazel.ColorComponent] = Hazel.ColorComponent(Vec4f0(color))
        end
    end

    nothing
end


function draw_vec3_control(label, values, reset=0f0, columnwidth=100f0)
    changed = false
    x = Ref(values[1])
    y = Ref(values[2])
    z = Ref(values[3])

    CImGui.PushID(label)
    CImGui.Columns(2)
    CImGui.SetColumnWidth(0, columnwidth)
    CImGui.Text(label)
    CImGui.NextColumn()

    CImGui.PushStyleVar(CImGui.ImGuiStyleVar_ItemSpacing, CImGui.ImVec2(0f0, 0f0))
    lineheight = CImGui.GetFontSize() + 2f0 * CImGui.GetStyle().FramePadding.y
    buttonsize = CImGui.ImVec2(lineheight + 3f0, lineheight)
    

    CImGui.PushItemWidth(0.33f0 * CImGui.CalcItemWidth())
    CImGui.PushStyleColor(CImGui.ImGuiCol_Button, CImGui.ImVec4(0.8f0, 0.1f0, 0.15f0, 1f0))
    CImGui.PushStyleColor(CImGui.ImGuiCol_ButtonHovered, CImGui.ImVec4(0.9f0, 0.2f0, 0.2f0, 1f0))
    CImGui.PushStyleColor(CImGui.ImGuiCol_ButtonActive, CImGui.ImVec4(0.8f0, 0.1f0, 0.15f0, 1f0))
    if CImGui.Button("X", buttonsize)
        changed = true
        x[] = reset
    end
    CImGui.PopStyleColor(3)
    CImGui.SameLine()
    changed = CImGui.DragFloat("##X", x, 0.1f0) || changed


    CImGui.SameLine()
    CImGui.PushStyleColor(CImGui.ImGuiCol_Button, CImGui.ImVec4(0.2f0, 0.7f0, 0.2f0, 1f0))
    CImGui.PushStyleColor(CImGui.ImGuiCol_ButtonHovered, CImGui.ImVec4(0.3f0, 0.8f0, 0.3f0, 1f0))
    CImGui.PushStyleColor(CImGui.ImGuiCol_ButtonActive, CImGui.ImVec4(0.2f0, 0.7f0, 0.2f0, 1f0))
    if CImGui.Button("Y", buttonsize)
        changed = true
        y[] = reset
    end
    CImGui.PopStyleColor(3)
    CImGui.SameLine()
    changed = CImGui.DragFloat("##Y", y, 0.1f0) || changed


    CImGui.SameLine()
    CImGui.PushStyleColor(CImGui.ImGuiCol_Button, CImGui.ImVec4(0.1f0, 0.25f0, 0.8f0, 1f0))
    CImGui.PushStyleColor(CImGui.ImGuiCol_ButtonHovered, CImGui.ImVec4(0.2f0, 0.35f0, 0.9f0, 1f0))
    CImGui.PushStyleColor(CImGui.ImGuiCol_ButtonActive, CImGui.ImVec4(0.1f0, 0.25f0, 0.8f0, 1f0))
    if CImGui.Button("Z", buttonsize)
        changed = true
        z[] = reset
    end
    CImGui.PopStyleColor(3)
    CImGui.SameLine()
    changed = CImGui.DragFloat("##Z", z, 0.1f0) || changed

    CImGui.PopStyleVar()
    CImGui.Columns(1)

    if changed
        values[1] = x[]
        values[2] = y[]
        values[3] = z[]
    end

    return changed
end