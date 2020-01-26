using Hazel
using Test

@testset "Hazel.jl" begin
    @testset "Buffers" begin
        include("Buffers.jl")
    end
end
