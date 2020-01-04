using Revise
using Hazel
# using GLFW

# implement Layer
struct ExampleLayer <: Hazel.AbstractLayer
    name::String
    ExampleLayer(name::String = "Example") = new(name)
end
Hazel.update!(l::ExampleLayer) = nothing
function Hazel.handle!(l::ExampleLayer, e::Hazel.KeyboardEvent{K}) where {K}
    @warn "$K: \t $(Char(Int64(K)))"
    true
end
Hazel.string(l::ExampleLayer) = l.name


app = DummyApplication()
# Hazel.pop_overlay!(app.layerstack)
push!(app, ExampleLayer())
run(app)


Hazel.GLFW.DestroyWindow(app.window.window)
