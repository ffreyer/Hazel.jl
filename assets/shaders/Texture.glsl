#type vertex
#version 330 core

layout(location = 0) in vec3 a_position; // a = attribute
layout(location = 1) in vec2 a_uv;

uniform mat4 u_projection_view;
uniform mat4 u_transform;

out vec2 v_uv; // v = varying

void main(){
    v_uv = a_uv;
    gl_Position = u_projection_view * u_transform * vec4(a_position, 1.0);
}


#type fragment
#version 330 core

layout(location = 0) out vec4 color; // a = attributed
uniform sampler2D u_texture;
in vec2 v_uv;

void main(){
    color = texture(u_texture, v_uv);
}
