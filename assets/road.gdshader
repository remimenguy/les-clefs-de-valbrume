shader_type spatial;
render_mode cull_disabled, diffuse_burley, depth_draw_never;

uniform sampler2D gravel : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D meadow : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grit : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool crossing = false;

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_position.xz;
	float center = 0.36 * sin((p.y - 34.5) * 0.19) + 0.27 * sin((p.y - 34.5) * 0.41);
	float width = 2.60 + 0.14 * sin(p.y * 0.7) + 0.12 * cos(p.y * 1.7);
	float offset = p.x - (p.y < 34.5 ? 0.0 : center);
	if (crossing) {
		offset = p.y - (46.12 + 1.62 * sin(abs(p.x) * 0.115) + 0.22 * sin(p.x * 0.44));
		width = 1.76;
	}
	float ragged = sin(p.x * 11.1 + p.y * 7.1) * 0.055 + cos(p.x * 3.2 - p.y * 4.4) * 0.11;
	float distance_to_center = (abs(offset) + ragged) / width;
	float edge = smoothstep(0.46, 0.97, distance_to_center);
	float wheel = 1.0 - 0.16 * exp(-pow((abs(offset) - width * 0.44) * 6.0, 2.0));
	vec3 dirt = texture(gravel, p * 0.51).rgb * vec3(0.77, 0.68, 0.57) * wheel;
	vec3 green = texture(meadow, p * 0.42).rgb * vec3(0.63, 0.68, 0.49);
	ALBEDO = mix(dirt, green, edge);
	ALPHA = 1.0 - smoothstep(0.66, 0.985, distance_to_center);
	vec2 bump = (texture(grit, p * 0.51).rg * 2.0 - 1.0) * 0.52 * (1.0 - edge);
	vec3 normal_world = normalize(vec3(bump.x, 1.0, -bump.y));
	NORMAL = normalize((VIEW_MATRIX * vec4(normal_world, 0.0)).xyz);
	ROUGHNESS = 0.94;
	SPECULAR = 0.23;
}
