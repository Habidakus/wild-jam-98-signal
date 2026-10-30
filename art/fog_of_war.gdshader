shader_type canvas_item;

uniform sampler2D fog_data;
uniform vec2 fog_size;

float apply_fog(float x, float y, float ul, float ur, float ll, float lr)
{
	float upper_alpha = mix(ul, ur, x);
	float lower_alpha = mix(ll, lr, x);
	float alpha = mix(upper_alpha, lower_alpha, y);
	return alpha;
}

void fragment() {
	vec2 pixel = UV * fog_size;
	vec2 UV_UL = vec2(floor(pixel.x), floor(pixel.y)) / fog_size;
	vec2 UV_LR = vec2(ceil(pixel.x), ceil(pixel.y)) / fog_size;
	vec2 UV_CENTER = (UV_UL + UV_LR) / 2.0;
	float alpha_center = texture(fog_data, UV_CENTER).a;
	float fx = fract(pixel.x);
	float fy = fract(pixel.y);
	if (fx < 0.5)
	{
		vec2 UV_CL = vec2(UV_UL.x, UV_CENTER.y);
		float alpha_cl = texture(fog_data, UV_CL).a;
		if (fy < 0.5)
		{
			vec2 UV_UC = vec2(UV_CENTER.x, UV_UL.y);
			float alpha_uc = texture(fog_data, UV_UC).a;
			vec2 UV_UR = vec2(UV_LR.x, UV_UL.y);
			float alpha_ur = texture(fog_data, UV_UR).a;
			float alpha_ul = texture(fog_data, UV_UL).a;
			float alpha = apply_fog(fx * 2.0, fy * 2.0, alpha_ul, alpha_uc, alpha_cl, alpha_center);
			COLOR = vec4(0, 0, 0, alpha);
		}
		else
		{
			vec2 UV_LL = vec2(UV_UL.x, UV_LR.y);
			float alpha_ll = texture(fog_data, UV_LL).a;
			vec2 UV_LC = vec2(UV_CENTER.x, UV_LR.y);
			float alpha_lc = texture(fog_data, UV_LC).a;
			float alpha = apply_fog(fx * 2.0, (fy - 0.5) * 2.0, alpha_cl, alpha_center, alpha_ll, alpha_lc);
			COLOR = vec4(0, 0, 0, alpha);
		}
	}
	else
	{
		vec2 UV_CR = vec2(UV_LR.x, UV_CENTER.y);
		float alpha_cr = texture(fog_data, UV_CR).a;
		if (fy < 0.5)
		{
			vec2 UV_UC = vec2(UV_CENTER.x, UV_UL.y);
			float alpha_uc = texture(fog_data, UV_UC).a;
			vec2 UV_UR = vec2(UV_LR.x, UV_UL.y);
			float alpha_ur = texture(fog_data, UV_UR).a;
			float alpha = apply_fog((fx - 0.5) * 2.0, fy * 2.0, alpha_uc, alpha_ur, alpha_center, alpha_cr);
			COLOR = vec4(0, 0, 0, alpha);
		}
		else
		{
			vec2 UV_LC = vec2(UV_CENTER.x, UV_LR.y);
			float alpha_lc = texture(fog_data, UV_LC).a;
			float alpha_lr = texture(fog_data, UV_LR).a;
			float alpha = apply_fog((fx - 0.5) * 2.0, (fy - 0.5) * 2.0, alpha_center, alpha_cr, alpha_lc, alpha_lr);
			COLOR = vec4(0, 0, 0, alpha);
		}
	}
}
