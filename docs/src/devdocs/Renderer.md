# [Renderer](@id Renderer_chapter)

The directory "src/Renderer" contains mostly interface functions and descriptions. See [OpenGL](@ref) for more details.

## Renderer

Renderer is is the exposed rendering api of Hazel. It interfaces with `RenderCommand`.

```@meta
CurrentModule = Hazel
```

```@docs
Renderer
draw_indexed
```

### AbstractGPUObject

Any type inheriting `AbstractGPuObject` implements

```@docs
bind
unbind
destroy(::AbstractGPUObject)
```

## VertexArray

A `VertexArray` is a GPUObject containing a vertex buffer and an index buffer. On top the `AbstractGPUObject` methods, it implements

```@docs
VertexArray
vertex_buffer
index_buffer
```

## Buffer

### VertexBuffer

A `VertexBuffer` is a GPUObject that handles `vertices` and their layout (via `BufferLayout`). On top of the `AbstractGPUObject` methods, it implements

```@docs
VertexBuffer
getlayout
```

### IndexBuffer

An `IndexBuffer` is a GPUObject that contains the indices making up triangles (or other GPU rendering primitives). On top of the `AbstractGPUObject` methods, it implements

```@doc
IndexBuffer
length(::IndexBuffer)
```

### BufferLayout

A BufferLayout describes the layout of a (vertex) buffer. A layout, in this case, refers to the types and sizes of different components of the (vertex) buffer. Currently only `LazyBufferLayout` exists.

```@docs
LazyBufferLayout
```

Typically using a buffer layout requires no more than specifying it and passing it to the related vertex array.

Internally, the BufferLayout are iterated when creating a vertex array. Iteration generates `BufferLayoutElements` that can be passed to

* `name`: Name of the vertex attribute. (Based on kwargs from generation)
* `type`: Type of the vertex attribute.
* `eltype`: Element type of a vertex attribute.
* `sizeof`: Size of the vertex attribute in bytes.
* `elsizeof`: Size of on element of the vertex attribute in bytes.
* `length`: Number of elements of a vertex attribute.
* `normalized`: Whether a vertex attribute should be normalized.
* `offset`: The offset of the vertex attribute (0-based)


## Shader

A `Shader` inherits from `AbstractGPUObject` and specifies a ... Shader.

```@doc
Shader
```

## GraphicsContext

A `GraphicsContext` wraps the native window and implements

```@docs
GraphicsContext
init(::GraphicsContext)
swap_buffers(::GraphicsContext)
native_window(::GraphicsContext)
```

For more implementation details, see [OpenGL](@ref)
