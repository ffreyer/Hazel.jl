@testset "BufferLayout" begin
    using Hazel: Normalize, BufferLayout, LazyBufferLayout, BufferLayoutElement
    using Hazel: type, normalized, offsets, types, name, offset, type, elsizeof

    test_types = (Float64, Int16, Point3f0, RGBA{Float32})
    eltypes = (Float64, Int16, Float32, Float32)
    byte_sizes = (8, 2, 12, 16)
    lengths = (1, 1, 3, 4)

    # Test Normalize
    for (L, B, ET, T) in zip(lengths, byte_sizes, eltypes, test_types)
        n = Normalize{T}
        @test type(n) == T
        @test sizeof(n) == B
        @test length(n) == L
        @test eltype(n) == ET
        @test normalized(n) == true
        @test normalized(Normalize{T, true}) == true
        @test normalized(Normalize{T, false}) == false
    end

    layout = BufferLayout(
        first = Float64,
        second = Normalize{Int16},
        third = Point3f0,
        fourth = RGBA{Float32}
    )

    # Test LazyBufferLayout
    @test layout isa LazyBufferLayout
    @test names(layout) == (:first, :second, :third, :fourth)
    @test length(layout) == 4
    @test sizeof(layout) == sum(byte_sizes)
    @test layout[1] == BufferLayoutElement(layout, 1)
    @test layout[end] == BufferLayoutElement(layout, 4)
    @test first(layout) == BufferLayoutElement(layout, 1)
    @test last(layout) == BufferLayoutElement(layout, length(layout))
    @test offsets(layout) == (0, 8, 10, 22)
    @test types(layout) == typeof(layout).parameters[1]

    # Test Iteration & BufferLayoutElement
    for (i, e) in enumerate(layout)
        @test e == BufferLayoutElement(layout, i)
        @test name(e) == names(layout)[i]
        @test offset(e) == (0, 8, 10, 22)[i]
        @test type(e) == test_types[i]
        @test length(e) == lengths[i]
        @test sizeof(e) == byte_sizes[i]
        @test eltype(e) == eltypes[i]
        @test elsizeof(e) == sizeof(eltypes[i])
        @test normalized(e) == (false, true, false, false)[i]
    end
end
