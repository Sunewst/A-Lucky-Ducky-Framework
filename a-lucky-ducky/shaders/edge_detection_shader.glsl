#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set = 0, binding = 0, std430) readonly buffer Params {
	vec2 raster_size;
	vec2 reserved;
	mat4 inv_proj_mat;
} params;

layout(rgba16f, set = 0, binding = 1) uniform image2D color_image;
layout(set = 0, binding = 2) uniform sampler2D depth_texture;
layout(set = 0, binding = 3) uniform sampler2D normal_texture;


const vec2 offset = vec2(0.0001);
const float line_highlight = 0.1;
const float line_shadow = 0.55;


float GetLinearDepth(vec2 uv, float mask) {
	float raw_depth = texture(depth_texture, uv).r * mask;
	vec3 ndc = vec3(uv * 2.0 - 1.0, raw_depth);
	vec4 view = params.inv_proj_mat * vec4(ndc, 1.0);
	view.xyz /= view.w;
	return -view.z;
}


vec4 GetNormal(vec2 uv, float mask){
	vec4 normal = texture(normal_texture, uv + offset) * mask;
	return normal;
}


vec4 NormalRoughnessCompatibility(vec4 p_normal_roughness) {
	float roughness = p_normal_roughness.w;
	if (roughness > 0.5) {
		roughness = 1.0 - roughness;
	}
	roughness /= (127.0 / 255.0);
	vec4 normal_comp = vec4(normalize(p_normal_roughness.xyz * 2.0 - 1.0) * 0.5 + 0.5, roughness);
	normal_comp = normal_comp * 2.0 - 1.0;
	return normal_comp;
}


float NormalEdgeIndicator(vec3 normal_edge_bias, vec3 normal, vec3 neighbor_normal, float depth_difference){
	float normal_difference = dot(normal - neighbor_normal, normal_edge_bias);
	float normal_indicator = clamp(smoothstep(-.01, .01, normal_difference), 0.0, 1.0);
	float depth_indicator = clamp(sign(depth_difference * .25 + .0025), 0.0, 1.0);
	return (1.0 - dot(normal, neighbor_normal)) * depth_indicator * normal_indicator;
}


void main() {
	vec2 size = params.raster_size;
	ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
	vec2 uv_normalized = uv / size;
	vec2 texel_size = 1.0 / size.xy;
	
	if (uv.x >= size.x || uv.y >= size.y) {
		return;
	}
	
	// UV ofssets
	vec2 uv_offsets[4];
	uv_offsets[0] = uv_normalized + vec2(0.0, -1.0) * texel_size + offset;
	uv_offsets[1] = uv_normalized + vec2(0.0, 1.0) * texel_size + offset;
	uv_offsets[2] = uv_normalized + vec2(1.0, 0.0) * texel_size + offset;
	uv_offsets[3] = uv_normalized + vec2(-1.0, 0.0) * texel_size + offset;

	
	float mask = texture(normal_texture, uv_normalized + offset).a;
	mask = ceil(mask);


	// Depth based Outlines
	float depth_difference = 0.0;
	float inv_depth_difference = 0.5;
	float depth = GetLinearDepth(uv_normalized + offset, mask);

	for (int i = 0; i < uv_offsets.length(); i++){
		float dOff = GetLinearDepth(uv_offsets[i], mask);
		depth_difference += clamp(dOff - depth, 0.0, 1.0);
		inv_depth_difference += depth - dOff;
	}

	inv_depth_difference = clamp(inv_depth_difference, 0.0, 1.0);
	inv_depth_difference = clamp(smoothstep(0.9, 0.9, inv_depth_difference) * 10.0 , 0.0, 1.0);
	depth_difference = smoothstep(0.45, 0.5, depth_difference);

	
	// Normal based Innerlines
	float normal_difference = 0.0;
	vec3 normal_edge_bias = vec3(1.0, 1.0, 1.0);
	vec3 normal = NormalRoughnessCompatibility(GetNormal(uv_normalized, mask)).rgb;

	for (int i = 0; i < uv_offsets.length(); i++){
		vec3 n_offset = NormalRoughnessCompatibility(GetNormal(uv_offsets[i], mask)).rgb;
		normal_difference += NormalEdgeIndicator(normal_edge_bias, normal, n_offset, depth_difference);
	}
	normal_difference = smoothstep(0.2, 0.2, normal_difference);
	normal_difference = clamp(normal_difference - inv_depth_difference, 0.0, 1.0);


	// Combine with screen render

	vec4 color = imageLoad(color_image, uv);

	vec3 outline = vec3(depth_difference);
	vec3 innerline = vec3(normal_difference) - outline;
	innerline = clamp(innerline, vec3(0.0), vec3(1.0));
	
	// Combine colors with lines
	vec4 color_with_lines = vec4(color.rgb + (innerline * line_highlight) - (color.rgb * outline * line_shadow), 1.0);

	imageStore(color_image, uv, color_with_lines);
}