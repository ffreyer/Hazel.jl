# OpenGL

The OpenGL directory includes OpenGL implementations of things defined in [Renderer_chapter](@ref).

## RenderCommand.jl

A RenderCommand is the "low level" version of `Renderer`. Currently implements `clear(::OpenGLRenderCommand[, color])` to clear the screen and `draw_indexed(::OpenglGLRenderCommand, vertex_array)` to draw a currently bound vertex array.

## VertexArray.jl

Implements

```@meta
CurrentModule = Hazel
```

```@docs
VertexArray
```

A VertexArray fully describes how vertices should be handled. VertexArray implements `bind`, `unbind`, `destroy` and the getters `vertex_buffer` and `index_buffer`.

## Buffer.jl

This file implements VertexBuffers and IndexBuffers.

### VertexBuffer

```@docs
VertexBuffer
```

A `VertexBuffer` sends an array fo vertices to the GPU. It also holds a BufferLayout, which is later linked by `VertexArray`. VertexBuffer implements `bind`, `dunbind`, `destroy` and the getter `layout`.

### IndexBuffer

```@docs
IndexBuffer
```

A `IndexBuffer` send an array of indices to the GPU. This is used to specify how vertices are connected. IndexBuffer implements `bind`, `unbind`, `destroy` and `length`

## Shader.jl

Implements

```@docs
Shader
```

following [this example](https://www.khronos.org/opengl/wiki/Shader_Compilation#Example). Shaders implement `bind`, `unbind` and `destroy`. A shader must be bound to be used, which will happen behind the scenes when using `Renderer`.


## gl_utils.jl

There is currently just one function in this directory, `gltype`. It returns a fitting `GLEnum` type for a given Julia type.
