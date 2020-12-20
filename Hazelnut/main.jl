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

# Should I just the application a module constant created on-init?
# or a closure like
#=
const app = let
    BasicApplication
end
=#
# everything in BasicApplication would need to be mutable
# and it should have an "off" state
# both are kinda true already, though there might need to be more cleanup
# of GLFW and CImGui
