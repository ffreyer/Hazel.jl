using Revise, Hazel

include("EditorLayer.jl")

begin
    app = BasicApplication("Hazelnut")
    # Hazel.disable_vsync(Hazel.window(app))
    try
        sl = EditorLayer()
        push!(app, sl)
    finally
        task = run(app)
    end
    nothing
end

# TODO (general)
# - check if CSyntax & (etc) avoids allocations
# - if yes switch to it I guess?
# - make texture options available
# - figure out if some clamping options of textures fix gaps between tiles

# TODO (ep 92)
# - make custom load/save dialogues
# - add shortcuts (Ctrl+O open, Ctrl+Shift+S Save as, Ctrl+N new)
# - maybe fix clear p.selected when changing p.scene
# - maybe add stages in entity creation

# TODO (ep 93)
# - write your own ImGuizmo library haha xD (3.5k loc, maybe...?)
# - with ctrl+q/w/e/r as shortcuts for nothing/translate/rotate/scale