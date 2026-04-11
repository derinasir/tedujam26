shader_type canvas_item;
render_mode unshaded;

uniform float spread : hint_range(0.0, 1.1) = 0.0;
uniform vec2 direction = vec2(1.0, 0.0);
uniform float arc_angle : hint_range(0.0, 360.0) = 360.0;
uniform float wave_count = 3.0;
uniform vec4 wave_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float thickness : hint_range(0.0, 1.0) = 0.05;

void fragment() {
	vec2 center_uv = UV - vec2(0.5);
	float dist = length(center_uv);
	
	float angle = degrees(atan(center_uv.y, center_uv.x));
	float dir_angle = degrees(atan(direction.y, direction.x));
	float angle_diff = abs(mod(angle - dir_angle + 180.0, 360.0) - 180.0);
	
	float wave_spacing = 0.15;
	float wave_field = 0.0;
	
	for(float i = 0.0; i < wave_count; i++) {
		float wave_dist = spread - (i * wave_spacing);
		float mask = smoothstep(thickness, 0.0, abs(dist - wave_dist));
		wave_field = max(wave_field, mask);
	}
	
	float angle_mask = step(angle_diff, arc_angle * 0.5);
	
	float distance_fade = smoothstep(0.5, 0.35, dist);
	float center_fade = smoothstep(0.0, 0.1, dist);
	float progress_fade = smoothstep(1.1, 0.8, spread);
	
	float alpha = wave_field * angle_mask * distance_fade * center_fade * progress_fade;
	
	COLOR = vec4(wave_color.rgb, alpha * wave_color.a);
}