shader_type canvas_item;

uniform vec4 top_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 bottom_color: source_color = vec4(0.46, 0.73, 0.0, 1.0);

void fragment() {
	vec4 texture_color = texture(TEXTURE, UV); 
	vec4 gradient_color = mix(top_color, bottom_color, SCREEN_UV.y);
	COLOR = vec4(gradient_color.rgb * texture_color.rgb, min(texture_color.a, gradient_color.a));
}
