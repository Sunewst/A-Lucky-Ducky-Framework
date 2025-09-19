shader_type spatial;

render_mode unshaded, depth_prepass_alpha;

void fragment() {
	ALBEDO.rb = vec2(0.0);
	ALBEDO.g = 1.0;
	float mask1 = sin((UV.y - TIME) * 4.0) * 0.2 + 0.6;
	float mask2 = sin((SCREEN_UV.x - TIME) * 30.0) * 0.2 + 0.8;
	float scanlines_factor = pow((sin((SCREEN_UV.y - TIME / 15.0) * 150.0) * 0.5 + 0.5), 2.5) * mask1 * mask2;

	float fresnel_factor = pow((1.0 - dot(VIEW, NORMAL)), 5);

	ALPHA = pow(scanlines_factor + fresnel_factor, 0.9);
}