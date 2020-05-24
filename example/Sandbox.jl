using Revise
using Hazel

include(joinpath(@__DIR__, "ExampleLayer.jl"))

app = Hazel.BasicApplication()
push!(app, ExampleLayer())
task = run(app)
