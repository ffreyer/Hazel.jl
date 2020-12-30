#type vertex
#version 450 core

layout(location = 0) in vec3 a_position; // a = attribute
layout(location = 1) in vec4 a_color;
layout(location = 2) in vec2 a_uv;
layout(location = 3) in float a_texture_index;
layout(location = 4) in float a_tilingfactor;

uniform mat4 u_projection_view;
out vec2 v_uv; // v = varying
out vec4 v_color;
out flat float v_texture_index;
out float v_tilingfactor;

void main(){
    v_color = a_color;
    v_uv = a_uv;
    v_texture_index = a_texture_index;
    v_tilingfactor = a_tilingfactor;
    gl_Position = u_projection_view * vec4(a_position, 1.0);
}


#type fragment
#version 450 core

layout(location = 0) out vec4 color; // a = attributed

in vec2 v_uv;
in vec4 v_color;
in flat float v_texture_index;
in float v_tilingfactor;

uniform sampler2D u_texture[32];

void main(){
    // color = texture(u_texture[int(v_texture_index)], v_uv * u_tilingfactor) * u_color;
    // color = texture(u_texture[int(v_texture_index)], v_uv) * v_color;
    vec4 texColor = v_color;
  	switch(int(v_texture_index)){
    		case 0: texColor  *= texture(u_texture[0],  v_tilingfactor * v_uv); break;
    		case 1: texColor  *= texture(u_texture[1],  v_tilingfactor * v_uv); break;
    		case 2: texColor  *= texture(u_texture[2],  v_tilingfactor * v_uv); break;
    		case 3: texColor  *= texture(u_texture[3],  v_tilingfactor * v_uv); break;
    		case 4: texColor  *= texture(u_texture[4],  v_tilingfactor * v_uv); break;
    		case 5: texColor  *= texture(u_texture[5],  v_tilingfactor * v_uv); break;
    		case 6: texColor  *= texture(u_texture[6],  v_tilingfactor * v_uv); break;
    		case 7: texColor  *= texture(u_texture[7],  v_tilingfactor * v_uv); break;
    		case 8: texColor  *= texture(u_texture[8],  v_tilingfactor * v_uv); break;
    		case 9: texColor  *= texture(u_texture[9],  v_tilingfactor * v_uv); break;
    		case 10: texColor *= texture(u_texture[10], v_tilingfactor * v_uv); break;
    		case 11: texColor *= texture(u_texture[11], v_tilingfactor * v_uv); break;
    		case 12: texColor *= texture(u_texture[12], v_tilingfactor * v_uv); break;
    		case 13: texColor *= texture(u_texture[13], v_tilingfactor * v_uv); break;
    		case 14: texColor *= texture(u_texture[14], v_tilingfactor * v_uv); break;
    		case 15: texColor *= texture(u_texture[15], v_tilingfactor * v_uv); break;
    		case 16: texColor *= texture(u_texture[16], v_tilingfactor * v_uv); break;
    		case 17: texColor *= texture(u_texture[17], v_tilingfactor * v_uv); break;
    		case 18: texColor *= texture(u_texture[18], v_tilingfactor * v_uv); break;
    		case 19: texColor *= texture(u_texture[19], v_tilingfactor * v_uv); break;
    		case 20: texColor *= texture(u_texture[20], v_tilingfactor * v_uv); break;
    		case 21: texColor *= texture(u_texture[21], v_tilingfactor * v_uv); break;
    		case 22: texColor *= texture(u_texture[22], v_tilingfactor * v_uv); break;
    		case 23: texColor *= texture(u_texture[23], v_tilingfactor * v_uv); break;
    		case 24: texColor *= texture(u_texture[24], v_tilingfactor * v_uv); break;
    		case 25: texColor *= texture(u_texture[25], v_tilingfactor * v_uv); break;
    		case 26: texColor *= texture(u_texture[26], v_tilingfactor * v_uv); break;
    		case 27: texColor *= texture(u_texture[27], v_tilingfactor * v_uv); break;
    		case 28: texColor *= texture(u_texture[28], v_tilingfactor * v_uv); break;
    		case 29: texColor *= texture(u_texture[29], v_tilingfactor * v_uv); break;
    		case 30: texColor *= texture(u_texture[30], v_tilingfactor * v_uv); break;
    		case 31: texColor *= texture(u_texture[31], v_tilingfactor * v_uv); break;
  	}
  	color = texColor;
    // color = texture(u_texture[int(v_texture_index)], v_uv) * v_color;
    // color = texture(u_texture[10], v_uv) * v_color;
    // color = u_color;
    // color.rgb = vec3(int(v_texture_index));
    // color.rg = v_uv;
}
