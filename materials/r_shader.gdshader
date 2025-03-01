// NOTE: Shader automatically converted from Godot Engine 4.3.stable's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx, sss_mode_skin;

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform float point_size : hint_range(0.1, 128.0, 0.1);

uniform float roughness : hint_range(0.0, 1.0);
uniform sampler2D texture_metallic : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_roughness_r, filter_linear_mipmap, repeat_enable;

uniform float specular : hint_range(0.0, 1.0, 0.01);
uniform float metallic : hint_range(0.0, 1.0, 0.01);

uniform sampler2D texture_normal : hint_roughness_normal, filter_linear_mipmap, repeat_enable;
uniform float normal_scale : hint_range(-16.0, 16.0);

uniform float subsurface_scattering_strength : hint_range(0.0, 1.0, 0.01);
uniform sampler2D texture_subsurface_scattering : hint_default_white, filter_linear_mipmap, repeat_enable;

uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

uniform float size = 0.4;
uniform float intensity = 0.7;

void vertex() {
	float frame_time = 0.1;
	float rounded_time = round(TIME / frame_time) * frame_time;
	
	float heightX = pow(abs(cos(VERTEX.y * size + rounded_time * 10.0)), 0.5) * intensity 
	 - pow(abs(cos(VERTEX.z * size * 0.7 + rounded_time * 5.0)), 0.5) * intensity * 1.3;          
	float heightY = pow(abs(cos(VERTEX.x * size + rounded_time * 15.0)), 0.5) * intensity 
	 - pow(abs(cos(VERTEX.z * size * 0.7 + rounded_time * 10.0)), 0.5) * intensity * 1.3;
	float heightZ = pow(abs(cos(VERTEX.y * size + rounded_time * 20.0)), 0.5) * intensity 
	 - pow(abs(cos(VERTEX.x * size * 0.7 + rounded_time * 15.0)), 0.5) * intensity * 1.3;
	VERTEX += vec3(heightX, heightY, heightZ);
}
void fragment() {
	vec2 base_uv = UV;

	vec4 albedo_tex = texture(texture_albedo, base_uv);
	ALBEDO = albedo.rgb * albedo_tex.rgb;

	float metallic_tex = dot(texture(texture_metallic, base_uv), metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	SPECULAR = specular;

	vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
	float roughness_tex = dot(texture(texture_roughness, base_uv), roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;

	// Normal Map: Enabled
	NORMAL_MAP = texture(texture_normal, base_uv).rgb;
	NORMAL_MAP_DEPTH = normal_scale;

	// Subsurface Scattering: Enabled
	float sss_tex = texture(texture_subsurface_scattering, base_uv).r;
	SSS_STRENGTH = subsurface_scattering_strength * sss_tex;
}
