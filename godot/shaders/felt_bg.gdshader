shader_type canvas_item;
render_mode blend_mix;

// Felt table background: fabric grain + radial vignette
float hash(vec2 p) {
	p = fract(p * vec2(127.1, 311.7));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * hash(p);
		p = p * 2.03 + vec2(5.2, 1.3);
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = UV;

	// High-frequency grain for fabric weave feel
	float grain = fbm(uv * 180.0) * 0.05 - 0.025;

	// Subtle horizontal weave lines (felt fabric)
	float weave = sin(uv.y * 320.0) * 0.008 + sin(uv.x * 320.0) * 0.004;

	// Base felt color — deep forest green
	vec3 felt = vec3(0.052, 0.128, 0.058);
	felt += grain + weave;

	// Radial vignette: dark edges, brighter center
	vec2 c = uv - 0.5;
	float vig = 1.0 - smoothstep(0.35, 0.85, length(c) * 1.6);
	felt = mix(felt * 0.45, felt, vig);

	// Subtle warm highlight near center
	float center_glow = smoothstep(0.5, 0.0, length(c) * 2.0) * 0.06;
	felt += center_glow;

	COLOR = vec4(clamp(felt, 0.0, 1.0), 1.0);
}
