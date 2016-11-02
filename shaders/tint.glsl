
uniform float tint;

vec4 effect(vec4 color, Image tex, vec2 tex_coord, vec2 screen_coord) {
    return clamp(tint,0.0,1.0) * Texel(tex, tex_coord);
}
