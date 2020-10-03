using Hazel

include("EditorLayer.jl")

begin
    app = BasicApplication()
    # Hazel.disable_vsync(Hazel.window(app))
    try
        sl = EditorLayer()
        push!(app, sl)
    finally
        task = run(app)
    end
    nothing
end
