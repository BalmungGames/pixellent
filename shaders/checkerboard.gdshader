shader_type canvas_item;

uniform float cell_size : hint_range(1.0, 64.0) = 8.0;
uniform vec4 color_a : source_color = vec4(0.78, 0.78, 0.80, 1.0);
uniform vec4 color_b : source_color = vec4(0.62, 0.62, 0.65, 1.0);

void fragment() {
	vec2 cell = floor(FRAGCOORD.xy / cell_size);
	float checker = mod(cell.x + cell.y, 2.0);
	COLOR = mix(color_a, color_b, checker);
}
