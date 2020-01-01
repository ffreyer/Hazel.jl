using Revise, Hazel
using GLFW

# implement Layer
struct ExampleLayer <: Hazel.AbstractLayer
    name::String
    ExampleLayer(name::String = "Example") = new(name)
end
Hazel.update!(l::ExampleLayer) = @info "update $l"
Hazel.handle!(l::ExampleLayer, e::Hazel.AbstractEvent) = begin @warn e; true end
Hazel.string(l::ExampleLayer) = l.name


app = DummyApplication()
push!(app, ExampleLayer())
run(app)


GLFW.DestroyWindow(app.window.window)
