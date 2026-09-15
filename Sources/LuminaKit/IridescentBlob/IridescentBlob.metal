#include <metal_stdlib>
using namespace metal;

vertex float4 fullscreenVertex(uint vid [[vertex_id]]) {
    float2 pos[3] = { float2(-1.0, -3.0), float2(3.0, 1.0), float2(-1.0, 1.0) };
    return float4(pos[vid], 0.0, 1.0);
}

struct Uniforms {
    float2 resolution;
    float  time;
    float  morph;
};

static inline float hash11(float p) {
    p = fract(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

static inline float valueNoise(float3 x) {
    float3 i = floor(x);
    float3 f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    float n = i.x + i.y * 157.0 + 113.0 * i.z;
    float a = hash11(n);
    float b = hash11(n + 1.0);
    float c = hash11(n + 157.0);
    float d = hash11(n + 158.0);
    float e = hash11(n + 113.0);
    float g = hash11(n + 114.0);
    float h = hash11(n + 270.0);
    float k = hash11(n + 271.0);
    return mix(mix(mix(a, b, f.x), mix(c, d, f.x), f.y),
               mix(mix(e, g, f.x), mix(h, k, f.x), f.y), f.z);
}

static inline float fbm3(float3 p) {
    float v = 0.0, a = 0.55;
    for (int i = 0; i < 3; i++) {
        v += a * valueNoise(p);
        p = p * 2.11 + 7.3;
        a *= 0.5;
    }
    return v;
}

static inline float3 rotY(float3 p, float a) {
    float c = cos(a), s = sin(a);
    return float3(c * p.x + s * p.z, p.y, -s * p.x + c * p.z);
}

static inline float3 rotX(float3 p, float a) {
    float c = cos(a), s = sin(a);
    return float3(p.x, c * p.y - s * p.z, s * p.y + c * p.z);
}

static inline float3 rotZ(float3 p, float a) {
    float c = cos(a), s = sin(a);
    return float3(c * p.x - s * p.y, s * p.x + c * p.y, p.z);
}

// Large smooth liquid folds — domain-warped ridged noise (cream / silk ribbons)
static inline float foldField(float3 p, float t) {
    // Slow domain warp for organic flow
    float3 q = p;
    q += 0.32 * float3(
        fbm3(p * 0.85 + float3(0.0, t * 0.14, 0.0)),
        fbm3(p * 0.75 + float3(t * 0.11, 0.0, 2.1)),
        fbm3(p * 0.95 + float3(3.0, 1.5, t * 0.09))
    );

    // Two ridged layers → thick soft ribbons
    float n1 = fbm3(q * 1.35 + float3(0.0, t * 0.16, t * 0.05));
    float n2 = fbm3(q * 2.0 - float3(t * 0.10, 0.0, t * 0.07));

    float r1 = 1.0 - abs(n1 * 2.0 - 1.0);
    r1 = r1 * r1 * (3.0 - 2.0 * r1);
    float r2 = 1.0 - abs(n2 * 2.0 - 1.0);
    r2 = r2 * r2 * (3.0 - 2.0 * r2);

    return (r1 - 0.5) * 1.05 + (r2 - 0.5) * 0.45 + (n1 - 0.5) * 0.28;
}

static inline float mapBlob(float3 p, float t, float morph) {
    float3 q = rotY(p, t * 0.14);
    q = rotX(q, sin(t * 0.08) * 0.18);
    q = rotZ(q, cos(t * 0.07) * 0.12);

    float r = length(q);
    float base = 0.62;

    float breathe = 1.0 + 0.025 * sin(t * 0.5) + 0.012 * sin(t * 0.87 + 1.1);

    // Large non-spherical silhouette
    float bulge = 0.09 * (fbm3(q * 0.7 + float3(t * 0.05, t * 0.04, 0.0)) - 0.5) * 2.0;

    // Primary fold displacement
    float folds = foldField(q, t) * 0.085 * (0.75 + 0.55 * morph);

    float radius = (base + bulge + folds) * breathe;
    return r - radius;
}

static inline float3 calcNormal(float3 p, float t, float morph) {
    const float2 e = float2(0.0016, 0.0);
    return normalize(float3(
        mapBlob(p + e.xyy, t, morph) - mapBlob(p - e.xyy, t, morph),
        mapBlob(p + e.yxy, t, morph) - mapBlob(p - e.yxy, t, morph),
        mapBlob(p + e.yyx, t, morph) - mapBlob(p - e.yyx, t, morph)
    ));
}

static inline float calcAO(float3 p, float3 n, float t, float morph) {
    float occ = 0.0, sca = 1.0;
    for (int i = 0; i < 5; i++) {
        float h = 0.02 + 0.055 * float(i);
        float d = mapBlob(p + n * h, t, morph);
        occ += (h - d) * sca;
        sca *= 0.62;
    }
    return saturate(1.0 - 2.0 * occ);
}

// Pastel thin-film — muted, mostly white with soft rainbow
static inline float3 iridescence(float cosTheta, float thickness) {
    float3 wave = float3(0.62, 0.52, 0.44);
    float3 phase = 6.2831853 * thickness / wave;
    float3 film = 0.5 + 0.5 * cos(phase + float3(0.05, 0.18, 0.35) + cosTheta * 2.2);
    // Pastel but still readable (cyan / lavender / rose / soft gold)
    float3 pastel = mix(float3(1.0), film, 0.52);
    float fres = pow(1.0 - saturate(cosTheta), 1.45);
    return mix(float3(1.0), pastel, saturate(0.10 + fres * 0.95));
}

static inline float softSpec(float3 n, float3 l, float3 v, float power) {
    float3 h = normalize(l + v);
    return pow(saturate(dot(n, h)), power);
}

struct RayHit {
    float  t;
    float  hit;
    float3 normal;
};

static inline RayHit raymarch(float3 ro, float3 rd, float time, float morph) {
    RayHit result;
    result.t = 0.0;
    result.hit = 0.0;
    result.normal = float3(0, 0, 1);

    float dist = 0.0;
    for (int i = 0; i < 100; i++) {
        float3 p = ro + rd * dist;
        float d = mapBlob(p, time, morph);
        if (d < 0.0010) {
            result.hit = 1.0;
            result.normal = calcNormal(p, time, morph);
            result.t = dist;
            return result;
        }
        if (dist > 6.0) break;
        dist += d * 0.60;
    }
    result.t = dist;
    return result;
}

fragment float4 iridescentBlobFragment(
    float4 position [[position]],
    constant Uniforms &u [[buffer(0)]]
) {
    float2 uv = (position.xy - 0.5 * u.resolution) / u.resolution.y;

    // Farther camera: blob ~42% of frame height, centered
    float3 ro = float3(0.0, 0.0, 4.20);
    float3 rd = normalize(float3(uv, -2.05));

    RayHit rh = raymarch(ro, rd, u.time, u.morph);
    float hit = rh.hit;
    float3 n = rh.normal;

    // Light cool-gray background
    float vig = 1.0 - 0.04 * length(uv * float2(0.5, 0.8));
    float3 bg = float3(0.948, 0.948, 0.952) * vig;

    if (hit < 0.5) {
        float2 q = uv;
        q.y += 0.10;
        float ground = exp(-dot(q, q) * 4.0) * 0.022;
        return float4(bg - ground, 1.0);
    }

    float3 p = ro + rd * rh.t;
    float3 v = -rd;
    float cosNV = saturate(dot(n, v));
    float fres = pow(1.0 - cosNV, 2.0);

    float3 key  = normalize(float3(-0.45, 0.72, 0.52));
    float3 fill = normalize(float3(0.85, -0.10, 0.48));
    float3 rim  = normalize(float3(0.05, 0.25, -0.95));

    float ao = calcAO(p, n, u.time, u.morph);

    // Warm milk-white pearl (reference is creamy, not pure white)
    float3 base = float3(0.965, 0.958, 0.948);

    float wrapKey  = saturate((dot(n, key) + 0.35) / 1.35);
    float wrapFill = saturate((dot(n, fill) + 0.45) / 1.45);

    // Form-first shading: high-key milky — valleys stay light, not dark gray
    float shade = 0.52 + 0.36 * wrapKey + 0.12 * wrapFill;
    shade *= mix(0.72, 1.0, ao);

    // Interior milky glow (subtle)
    float interior = 0.14 + 0.10 * cosNV;

    float3 col = base * (shade + interior);

    // Iridescence: edges + fold creases (the reference's pastel ridge language)
    float fold = foldField(p, u.time);
    float crease = saturate(0.5 + 0.5 * fold);
    float thickness = 1.0 + 0.70 * crease + 0.55 * fres + 0.20 * fbm3(p * 2.0);
    float3 irid = iridescence(cosNV, thickness);

    // Body stays white; color lives on silhouette edges and fold crests
    float iridAmt = saturate(fres * 0.85 + crease * 0.25 + crease * fres * 0.45 + 0.06);
    col = mix(col, col * irid, iridAmt);

    // High-gloss specular streaks along ridges
    float sp1 = softSpec(n, key,  v, 28.0);
    float sp2 = softSpec(n, fill, v, 10.0);
    float sp3 = softSpec(n, rim,  v, 5.0);
    // Tight hot core + broad soft halo (glossy ribbon language)
    float spCore = softSpec(n, key, v, 90.0);
    float3 spec = float3(1.0) * (sp1 * 0.55 + sp2 * 0.22 + sp3 * 0.12 + spCore * 0.35);

    // Extra highlight boost on fold crests (glossy ribbon look)
    spec += float3(1.0) * (sp1 + spCore) * crease * 0.28;

    // Broad soft sheen (high-gloss latex / pearl)
    float3 sheen = irid * pow(fres, 1.4) * 0.28;

    // Silhouette soft light
    col += float3(0.93, 0.94, 0.97) * pow(fres, 3.0) * 0.22;
    col += sheen + spec;

    // Tiny sparkle on hottest highlight
    col += float3(pow(softSpec(n, key, v, 140.0), 2.0) * 0.12);

    // Soft shoulder, keep high-key milky
    col = col / (1.0 + max(col - 0.85, 0.0) * 0.55);
    col = pow(saturate(col), float3(0.97));

    // Very gentle luminous edge bleed
    col = mix(col, col + float3(0.02, 0.022, 0.028), fres * 0.35);

    return float4(col, 1.0);
}
