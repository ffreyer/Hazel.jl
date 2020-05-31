#type vertex
#version 330 core

layout(location = 0) in vec3 a_position;

uniform mat4 u_projection_view;
// uniform mat4 u_transform;

void main(){
    gl_Position = u_projection_view * vec4(a_position, 1.0);
}


#type fragment
#version 330 core

layout(location = 0) out vec4 color; // a = attributed

uniform vec4 u_color;

void main(){
    color = u_color;
}
