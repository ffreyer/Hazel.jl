using CImGui
using Hazel
using Overseer
using CImGui.CSyntax.CStatic

mutable struct SceneHierarchyPanel
    scene::Scene
    selected::Union{Nothing, Hazel.Entity}

    SceneHierarchyPanel(scene::Scene) = new(scene, nothing)
end

context!(p::SceneHierarchyPanel, s::Scene) = p.scene = s



@HZ_profile function render!(p::SceneHierarchyPanel)
    CImGui.Begin("Scene Hierarchy")
    reg = Hazel.registry(p.scene)
    for e in entities(reg)
        e == Hazel.Overseer.EMPTY_ENTITY && continue
        entity = Hazel.Entity(p.scene, e)
        draw_entity_node!(p, entity)
    end

    # We can't do this the way we have the struct, right?
    if CImGui.IsMouseDown(0) && CImGui.IsWindowHovered()
        p.selected = nothing
    end

    # Right click on blank space
    # CImGui.ImGuiPopupFlags_
    if CImGui.BeginPopupContextWindow(C_NULL, 
            CImGui.ImGuiPopupFlags_NoOpenOverItems |
            CImGui.ImGuiPopupFlags_MouseButtonRight
        )
        if CImGui.MenuItem("Create Empty Entity")
            Hazel.Entity(p.scene, Hazel.NameComponent("New Entity"), Hazel.Transform())
        end
        CImGui.EndPopup()
    end
    CImGui.End()

    CImGui.Begin("Properties")
    if p.selected !== nothing
        draw_components!(p, p.selected)
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
        CImGui.ImGuiTreeNodeFlags_OpenOnArrow |
        CImGui.ImGuiTreeNodeFlags_SpanAvailWidth

    opened = CImGui.TreeNodeEx(
        Ptr{Cvoid}(Hazel.RawEntity(entity).id), flags, string(entity[NameComponent])
    )

    CImGui.IsItemClicked() && (p.selected = entity)

    should_delete = false
    if CImGui.BeginPopupContextItem()
        should_delete = CImGui.MenuItem("Delete Entity")
        CImGui.EndPopup()
    end

    if opened
        flags = CImGui.ImGuiTreeNodeFlags_OpenOnArrow
        opened = CImGui.TreeNodeEx(
            Ptr{Cvoid}(Hazel.RawEntity(entity).id + UInt32(1000000)), flags, 
            entity[NameComponent].name
        )
        if opened
            CImGui.TreePop()
        end
        CImGui.TreePop()
    end

    if should_delete
        if p.selected == entity
            p.selected = nothing
        end
        Hazel.delete!(entity)
    end
    nothing
end



# wraps a begin ... end block in a TreeNode and check if the component is available
macro componentUI(component, name, code, delete_block)
    esc(quote
        if haskey(entity, $component)
            region = CImGui.GetContentRegionAvail()
            CImGui.PushStyleVar(CImGui.ImGuiStyleVar_FramePadding, CImGui.ImVec2(4,4))
            lineheight = CImGui.GetFontSize() + 8f0 #CImGui.ImGuiStyleVar_FramePadding.y * 2.0f0
            CImGui.Separator()
            open = CImGui.TreeNodeEx(Ptr{Cvoid}(hash($component)), flags, $name)
            CImGui.PopStyleVar()
            CImGui.SameLine(region.x - lineheight * 0.5f0)
            if CImGui.Button("+", CImGui.ImVec2(lineheight, lineheight))
                CImGui.OpenPopup("ComponentSettings")
            end

            remove = false
            if CImGui.BeginPopup("ComponentSettings")
                if CImGui.MenuItem("Remove Component")
                    remove = true
                end
                CImGui.EndPopup()
            end
            # CImGui.PopStyleVar()

            if open
                $code
                CImGui.TreePop()
            end

            if remove
                $delete_block
            end
        end
    end)
end

function draw_components!(p, entity::Hazel.Entity)
    # TODO
    # Would be nice to have buffer and position as static things
    flags = CImGui.ImGuiTreeNodeFlags_DefaultOpen |
            CImGui.ImGuiTreeNodeFlags_AllowItemOverlap |
            CImGui.ImGuiTreeNodeFlags_SpanAvailWidth |
            CImGui.ImGuiTreeNodeFlags_Framed |
            CImGui.ImGuiTreeNodeFlags_FramePadding

    if haskey(entity, NameComponent)
        name = string(entity[NameComponent])
        buffer = name * "\0"^256
        if CImGui.InputText("##Tag", buffer, length(buffer))
            entity[NameComponent] = NameComponent(strip(buffer, '\0'))
        end
    end


    CImGui.SameLine()
    CImGui.PushItemWidth(-1)
    CImGui.Button("Add Component") && CImGui.OpenPopup("AddComponent")
    if CImGui.BeginPopup("AddComponent")
        if CImGui.MenuItem("Camera")
            push!(p.selected, Hazel.CameraComponent())
            CImGui.CloseCurrentPopup()
        end
        if CImGui.MenuItem("Quad")
            t = p.selected[Hazel.Transform]
            push!(
                p.selected, 
                Hazel.InstancedQuad(t, Hazel.blank_texture(p.scene))
            )
            CImGui.CloseCurrentPopup()
        end
        CImGui.EndPopup()
    end
    CImGui.PopItemWidth()


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
    end begin
        delete!(entity, Hazel.Transform)
    end


    @componentUI Hazel.CameraComponent "Camera" begin
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
    end begin
        delete!(entity, Hazel.CameraComponent)
    end


    # @componentUI Hazel.QuadVertices "Sprite Renderer" begin
    @componentUI Hazel.InstancedQuad "Instanced Quad" begin
        quad = entity[Hazel.InstancedQuad]

        visible = Ref(quad.visible)
        if CImGui.Checkbox("Visible", visible)
            quad.visible = visible[]
        end
        color = Vector(quad.color)
        if CImGui.ColorEdit4("Color", color)
            quad.color = Vec4f0(color)
        end
        buffer = quad.texture.path * "\0"^256
        if CImGui.InputText("Texture path", buffer, length(buffer))
            #entity[NameComponent] = NameComponent(strip(buffer, '\0'))
            @info "TODO"
        end
        tf = Ref(quad.tilingfactor)
        if CImGui.DragFloat("Tiling Factor", tf, 0.05f0)
            quad.tilingfactor = tf[]
        end
    end begin
        delete!(entity, Hazel.InstancedQuad)
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

    CImGui.PopItemWidth()
    CImGui.PopStyleVar()
    CImGui.Columns(1)
    CImGui.PopID()

    if changed
        values[1] = x[]
        values[2] = y[]
        values[3] = z[]
    end

    return changed
end