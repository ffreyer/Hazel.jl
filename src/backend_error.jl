struct MissingBackendException
    name::Symbol
end

function Base.showerror(io::IO, ex::MissingBackendException)
    print(io, "No backend implementation for $(ex.name).")
end

"""
    @backend backend_function

Expands to

    backend_function(args...; kwargs...) = throw(MissingBackendException(:backend_function))
"""
macro backend(name::Symbol)
    esc(:($name(args...; kwargs...) = throw(MissingBackendException($name))))
end
"""
    @backend backend_function(arg1, arg2)

Expands to

    backend_function(arg1, arg2) = throw(MissingBackendException(:backend_function))
"""
macro backend(expr::Expr)
    esc(:($expr = throw(MissingBackendException($(expr.args[1])))))
end
