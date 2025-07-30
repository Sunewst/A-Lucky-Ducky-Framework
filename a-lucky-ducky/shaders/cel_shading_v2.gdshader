shader_type spatial;
render_mode depth_draw_opaque, specular_schlick_ggx;

// Material Properties
group_uniforms Material;

// Material: Base Color
group_uniforms Material.BaseColor;
uniform vec3 albedo : source_color = vec3(1.0);
uniform bool use_texture_albedo = false;
uniform sampler2D albedo_texture : source_color, filter_linear, repeat_enable;

// Material: Surface Properties
group_uniforms Material.Surface;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.5;

// Material: Normal Map
group_uniforms Material.Normal;
uniform bool use_normal_map = false;
uniform sampler2D normal_texture : hint_normal, filter_linear;

// Material: Emission
group_uniforms Material.Emission;
uniform bool use_emission_map = false;
uniform sampler2D emission_texture : source_color, filter_linear, repeat_enable;
uniform vec3 emission_color : source_color = vec3(0.0);
uniform float emission_intensity : hint_range(0.0, 2.0) = 1.0;

// Lighting Properties
group_uniforms Lighting;

// Lighting: Ambient
group_uniforms Lighting.Ambient;
uniform bool use_ambient_light = true;
uniform vec3 ambient_light : source_color = vec3(0.447, 0.490, 0.620);

// Lighting: Specular
group_uniforms Lighting.Specular;
uniform float shininess : hint_range(1.0, 128.0) = 32.0;
uniform float specular_intensity : hint_range(0.0, 2.0) = 1.0;
uniform vec3 specular_color : source_color = vec3(1.0);

// Lighting: Rim
group_uniforms Lighting.Rim;
uniform float rim_strength : hint_range(0.0, 1.0) = 1.0;

// Lighting: Shadow
group_uniforms Lighting.Shadow;
uniform float shadow_intensity : hint_range(0.0, 1.0) = 0.5;
uniform vec3 shadow_color : source_color = vec3(0.2);

// Cel Shading Properties
group_uniforms CelShading;

// CelShading: General
group_uniforms CelShading.General;
uniform bool use_half_lambert = false;
uniform bool use_ramp = false;
uniform sampler2D ramp : source_color, filter_linear;
uniform vec2 ramp_offset = vec2(0.0, 0.0);
uniform bool use_borders = false;
uniform float border_width : hint_range(0.0, 0.1) = 0.01;

// CelShading: Diffuse
group_uniforms CelShading.Diffuse;
uniform float diffuse_threshold : hint_range(0.0, 1.0) = 0.5;
uniform float diffuse_smoothness : hint_range(0.0, 1.0) = 0.5;

// CelShading: Specular
group_uniforms CelShading.Specular;
uniform float specular_threshold : hint_range(0.0, 1.0) = 0.5;
uniform float specular_smoothness : hint_range(0.0, 1.0) = 0.0;

// CelShading: Rim
group_uniforms CelShading.Rim;
uniform float rim_threshold : hint_range(0.0, 1.0) = 0.7;
uniform float rim_smoothness : hint_range(0.0, 1.0) = 0.0;
uniform float rim_distance_falloff : hint_range(0.0, 10.0) = 1.0;

// CelShading: Cuts
group_uniforms CelShading.Cuts;
uniform int directional_cuts : hint_range(1, 10) = 3;
uniform int non_directional_cuts : hint_range(1, 10) = 3;

// CelShading: Lighting Adjustments
group_uniforms CelShading.LightingAdjustments;
uniform float wrap : hint_range(-2.0, 2.0) = 0.0;
uniform float steepness : hint_range(1.0, 8.0) = 1.0;

// Outline Properties
group_uniforms Outline;

// Outline: General
group_uniforms Outline.General;
uniform bool use_outline = false;
uniform vec3 outline_color : source_color = vec3(0.0);
uniform float outline_threshold : hint_range(0.0, 1.0) = 0.7;
uniform float outline_smoothness : hint_range(0.0, 0.1) = 0.01;

void vertex() {
    // No vertex-based outline, handled in fragment
}

void fragment() {
    vec3 base_color = use_texture_albedo ? texture(albedo_texture, UV).rgb : albedo;

    if (use_normal_map) {
        vec3 tex_normal = texture(normal_texture, UV).rgb * 2.0 - 1.0;
        NORMAL = normalize(TANGENT * tex_normal);
    }

    vec3 emission = use_emission_map ? texture(emission_texture, UV).rgb * emission_color * emission_intensity : emission_color * emission_intensity;

    if (use_outline) {
        float outline_factor = 1.0 - dot(NORMAL, VIEW);
        float outline = smoothstep(outline_threshold - outline_smoothness, outline_threshold + outline_smoothness, outline_factor);
        if (outline > 0.5) {
            ALBEDO = vec3(0.0); // No lighting contribution
            EMISSION = outline_color; // Unlit outline color
        } else {
            ALBEDO = base_color;
            if (use_ambient_light) {
                EMISSION = base_color * ambient_light + emission;
            } else {
                EMISSION = emission;
            }
        }
    } else {
        ALBEDO = base_color;
        if (use_ambient_light) {
            EMISSION = base_color * ambient_light + emission;
        } else {
            EMISSION = emission;
        }
    }

    METALLIC = metallic;
    ROUGHNESS = roughness;
}

void light() {
    vec3 normal = NORMAL;
    vec3 light_dir = LIGHT;

    float NdotL = dot(normal, light_dir);
    float diffuse;
    if (use_half_lambert) {
        diffuse = pow(0.5 * NdotL + 0.5, 2.0);
        diffuse = clamp(diffuse * steepness + wrap, 0.0, 1.0);
        diffuse = smoothstep(
            diffuse_threshold - diffuse_smoothness,
            diffuse_threshold + diffuse_smoothness,
            diffuse
        );
    } else {
        diffuse = clamp(NdotL + wrap, 0.0, 1.0) * steepness;
        diffuse = smoothstep(
            diffuse_threshold - diffuse_smoothness,
            diffuse_threshold + diffuse_smoothness,
            diffuse
        );
    }
    diffuse *= ATTENUATION;

    int cuts = LIGHT_IS_DIRECTIONAL ? directional_cuts : non_directional_cuts;
    float cuts_inv = 1.0 / float(cuts);
    float diffuse_cell = floor(diffuse * float(cuts)) * cuts_inv;

    float border = 0.0;
    if (use_borders) {
        float corr_border_width = length(cross(normal, light_dir)) * border_width * steepness;
        border = step(diffuse_cell - corr_border_width, diffuse)
               - step(1.0 - corr_border_width, diffuse);
    }

    vec3 diffuse_contrib = mix(ALBEDO, shadow_color, shadow_intensity) * LIGHT_COLOR / 3.14159;
    if (use_ramp) {
        diffuse_contrib *= texture(ramp, vec2(diffuse_cell * (1.0 - border), 0.0) + ramp_offset).rgb;
    } else {
        diffuse_contrib *= diffuse_cell * (1.0 - border);
    }

    float dist_atten = LIGHT_IS_DIRECTIONAL ? 1.0 : ATTENUATION;

    vec3 halfway = normalize(light_dir + VIEW);
    float specular = pow(clamp(dot(normal, halfway), 0.0, 1.0), shininess) * specular_intensity;
    float specular_cell = smoothstep(
        specular_threshold - specular_smoothness,
        specular_threshold + specular_smoothness,
        specular
    );

    float rim = clamp(1.0 - dot(normal, VIEW), 0.0, 1.0);
    float rim_distance_atten = clamp(1.0 / (length(VIEW) * rim_distance_falloff), 0.0, 1.0);
    float rim_cell = smoothstep(
        rim_threshold - rim_smoothness,
        rim_threshold + rim_smoothness,
        rim
    ) * rim_distance_atten;

    vec3 highlight_color = specular_color * LIGHT_COLOR * (specular_cell + rim_cell * rim_strength);
    float light_contrib = diffuse_cell;
    DIFFUSE_LIGHT += (diffuse_contrib * light_contrib + highlight_color) * dist_atten;
}