# TODO rework
# We probably want to record N timing for every block,
# so that we can generate real tiem performance graphs

# Cherno's implementation is this:
# https://gist.github.com/TheCherno/31f135eea6ee729ab5f26a6908eb3a5e

# Btw, file writes are actually rather fast
# julia> @benchmark write($file, $msg)
# BenchmarkTools.Trial:
#   memory estimate:  0 bytes
#   allocs estimate:  0
#   --------------
#   minimum time:     38.246 ns (0.00% GC)
#   median time:      41.535 ns (0.00% GC)
#   mean time:        47.561 ns (0.00% GC)
#   maximum time:     180.706 ns (0.00% GC)
#   --------------
#   samples:          10000
#   evals/sample:     991


"""
    @HZ_profile function ... end
    @HZ_profile foo(args...) = ...
    @HZ_profile "name" begin ... end

Wraps the body of a function with `@timeit_debug <function name> begin ... end`.

The `@timeit_debug` macro can be disabled. When it is, it should come with zero
overhead. To enable timing, use `TimerOutputs.enable_debug_timings(<module>)`.
See TimerOutputs.jl for more details.

Benchmarks/Timings can be retrieved using `print_timer()` and reset with
`reset_timer!()`. It should be no problem to add additonal `@timeit_debug` to
a function.
"""
macro HZ_profile(args...)
    if length(args) == 1 && args[1].head in (Symbol("="), :function)
        expr = args[1]
        code = TimerOutputs.timer_expr(
            Hazel, true,
            string(expr.args[1]), # name is the function call signature
            :(begin $(expr.args[2]) end) # inner code block
        )
        Expr(
            expr.head,     # function or =
            esc(expr.args[1]),  # function name w/ args
            code
        )
    else
        # Not a function, just do the same as timeit_debug
        # This is copied from TimerOutputs.jl
        # With __module__ replaced by Hazel because we want to have all timings
        # in the Hazel namespace
        TimerOutputs.timer_expr(Hazel, true, args...)
    end
end


timeit_debug_enabled() = false

"""
    enable_profiling()

Enables benchmarking for `Hazel`.

This affects every function with the `Hazel.@HZ_profile` macro as well as any
`TimerOutputs.@timeit_debug` blocks. Benchmarks are recorded to the default
TimerOutput `TimerOutputs.DEFAULT_TIMER`. Results can be printed via
`TimerOutputs.print_timer()`.

[`disable_benchmarks`](@ref)
"""
enable_profiling() = TimerOutputs.enable_debug_timings(Hazel)

"""
    disable_benchmarks()

Disables benchmarking for `Hazel`.

This affects every function with the `Hazel.@HZ_profile` macro as well as any
`TimerOutputs.@timeit_debug` blocks.

[`enable_benchmarks`](@ref)
"""
disable_profiling() = TimerOutputs.disable_debug_timings(Hazel)
