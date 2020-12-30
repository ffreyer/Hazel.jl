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

# TODO
# - make custom load/save dialogues
# - add shortcuts (Ctrl+O open, Ctrl+Shift+S Save as, Ctrl+N new)
# - maybe fix clear p.selected when changing p.scene
# - maybe add stages in entity creation