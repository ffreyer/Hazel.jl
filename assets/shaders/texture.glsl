#type vertex
#version 330 core

layout(location = 0) in vec3 a_position; // a = attribute
layout(location = 1) in vec4 a_color;
layout(location = 2) in vec2 a_uv;

uniform mat4 u_projection_view;
out vec2 v_uv; // v = varying
out vec4 v_color; // v = varying

void main(){
    v_color = a_color;
    v_uv = a_uv;
    gl_Position = u_projection_view * vec4(a_position, 1.0);
}


#type fragment
#version 330 core

layout(location = 0) out vec4 color; // a = attributed

in vec2 v_uv;
in vec4 v_color;

uniform sampler2D u_texture;
uniform vec4 u_color;
uniform float u_tilingfactor;

void main(){
    // color = texture(u_texture, v_uv * u_tilingfactor) * u_color;
    color = v_color;
}
