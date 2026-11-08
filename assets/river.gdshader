shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

varying vec3 position_world;

void vertex() {
	position_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = position_world.xz;
	float a = dot(p, vec2(1.37, 4.8)) + TIME * 1.45;
	float b = dot(p, vec2(-1.02, 2.28)) - TIME * 0.94;
	float c = dot(p, vec2(4.72, 6.93)) + TIME * 2.23;
	vec2 slope = cos(a) * vec2(0.020, 0.071) +
		cos(b) * vec2(-0.021, 0.047) + cos(c) * vec2(0.012, 0.016);
	vec3 water_normal = normalize(vec3(-slope.x, 1.0, -slope.y));
	NORMAL = normalize((VIEW_MATRIX * vec4(water_normal, 0.0)).xyz);
	float banks = smoothstep(3.15, 3.7, abs(p.y - 29.9));
	float ripples = (sin(a) + sin(b)) * 0.021;
	vec3 deep = vec3(0.028, 0.092, 0.087);
	vec3 shallow = vec3(0.074, 0.122, 0.080);
	ALBEDO = mix(deep, shallow, banks) + vec3(ripples * 0.25);
	METALLIC = 0.28;
	ROUGHNESS = 0.19 + 0.10 * banks;
	SPECULAR = 0.68;
}
