using Revise, Hazel
using GLFW

# implement Layer
struct ExampleLayer <: Hazel.AbstractLayer
    name::String
    ExampleLayer(name::String = "Example") = new(name)
end
Hazel.on_update(l::ExampleLayer) = @info "update $l"
Hazel.on_event(l::ExampleLayer, e::Hazel.AbstractEvent) = @warn e
Hazel.name(l::ExampleLayer) = l.name


app = DummyApplication()
push!(app, ExampleLayer())
run(app)


GLFW.DestroyWindow(app.window.window)
