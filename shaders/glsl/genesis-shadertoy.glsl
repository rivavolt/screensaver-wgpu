// "Genesis" - A universe dreaming itself into existence
// Paste this into Shadertoy.com -> New -> paste in "Image" tab

#define TAU 6.28318530718
#define PHI 1.61803398875

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec3 hash3(vec2 p) {
    return vec3(hash(p), hash(p + 37.0), hash(p + 71.0));
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p, int octaves) {
    float v = 0.0;
    float a = 0.5;
    mat2 rot = mat2(0.8, 0.6, -0.6, 0.8);
    for (int i = 0; i < octaves; i++) {
        v += a * noise(p);
        p = rot * p * 2.0;
        a *= 0.5;
    }
    return v;
}

vec3 dreamColor(float t, float mood) {
    vec3 c1 = vec3(0.1, 0.0, 0.2);
    vec3 c2 = vec3(0.0, 0.3, 0.4);
    vec3 c3 = vec3(0.4, 0.1, 0.3);
    vec3 c4 = vec3(0.1, 0.4, 0.3);
    vec3 c5 = vec3(0.5, 0.3, 0.1);

    vec3 col = mix(c1, c2, sin(t * TAU) * 0.5 + 0.5);
    col = mix(col, c3, sin(t * TAU * PHI) * 0.5 + 0.5);
    col = mix(col, c4, sin(t * TAU / PHI + mood) * 0.5 + 0.5);
    col = mix(col, c5, sin(t * TAU * 0.5 + mood * 2.0) * 0.3 + 0.2);
    return col;
}

vec3 soul(float t) {
    return 0.5 + 0.5 * cos(TAU * (t + vec3(0.0, 0.1, 0.2)));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec2 p = (uv * 2.0 - 1.0);
    p.x *= iResolution.x / iResolution.y;

    float t = iTime * 0.08;
    vec3 col = vec3(0.0);

    float breath = sin(t * 0.5) * 0.5 + 0.5;
    float heartbeat = pow(sin(t * 1.2) * 0.5 + 0.5, 8.0);

    // === THE BREATHING VOID ===
    float voidNoise = fbm(p * 3.0 + t * 0.1, 5);
    vec3 voidCol = dreamColor(voidNoise, t);
    col += voidCol * voidNoise * voidNoise * 0.1 * (0.7 + breath * 0.3);

    // === COSMIC JELLYFISH ===
    for (float i = 0.0; i < 4.0; i++) {
        float jt = t * 0.3 + i * PHI;
        vec2 jc = vec2(sin(jt) * 0.5 + sin(jt * PHI) * 0.2,
                       cos(jt * 0.7) * 0.4 + cos(jt * PHI * 0.5) * 0.15);

        float jd = length(p - jc);
        float pulse = sin(t * 2.0 + i * 1.5) * 0.3 + 0.7;
        float bellSize = 0.15 * pulse;
        float bell = smoothstep(bellSize, bellSize * 0.3, jd);

        float tentGlow = 0.0;
        for (float j = 0.0; j < 5.0; j++) {
            float ta = j * TAU / 5.0 + sin(t + i) * 0.5;
            float tl = 0.3 + sin(t * 0.5 + j) * 0.1;

            for (float k = 0.0; k < 10.0; k++) {
                float seg = k / 10.0;
                float wave = sin(seg * 8.0 + t * 3.0 + j) * 0.05 * seg;
                vec2 tp = jc + vec2(sin(ta + wave) * seg * tl, -seg * tl * 0.8 - 0.05);
                tentGlow += exp(-length(p - tp) * 40.0) * (1.0 - seg * 0.8) * 0.15;
            }
        }

        vec3 jellCol = soul(i * 0.25 + t * 0.1);
        float innerGlow = exp(-jd * 4.0) * 0.5;
        col += jellCol * (bell * 0.6 + innerGlow + tentGlow) * (0.4 + heartbeat * 0.2);
    }

    // === THREADS OF FATE ===
    for (float i = 0.0; i < 7.0; i++) {
        float sp = t * 0.15 + i * TAU / 7.0;
        float sy = sin(sp) * 0.6;

        float stringInt = 0.0;
        for (float x = -1.5; x < 1.5; x += 0.05) {
            float w1 = sin(x * 5.0 + t * 2.0 + i) * 0.1;
            float w2 = sin(x * 8.0 - t * 1.5 + i * PHI) * 0.05;
            vec2 spos = vec2(x, sy + w1 + w2);
            stringInt += exp(-length(p - spos) * 30.0) * 0.03;
        }

        col += dreamColor(i * 0.14 + t * 0.05, sin(i)) * stringInt * 1.5;
    }

    // === IMPOSSIBLE GEOMETRY ===
    vec2 geo = p;
    vec3 geoCol = vec3(0.0);

    for (float i = 0.0; i < 5.0; i++) {
        geo = abs(geo) - 0.4 + sin(t * 0.3 + i) * 0.1;
        float c = cos(t * 0.1 + i);
        float s = sin(t * 0.1 + i);
        geo = mat2(c, s, -s, c) * geo;

        float d = length(geo) - 0.1;
        geoCol += soul(length(p) + i * 0.2 + t * 0.3) * exp(-abs(d) * 20.0) * 0.15;
    }
    col += geoCol;

    // === BIRTH OF STARS ===
    vec2 sf = p * 20.0 + vec2(t * 0.2, t * 0.15);
    vec2 si = floor(sf);
    vec2 sff = fract(sf) - 0.5;

    float sr = hash(si);
    if (sr > 0.9) {
        vec2 soff = (hash3(si).xy - 0.5) * 0.7;
        float sd = length(sff - soff);
        float life = sin(t * 0.5 + sr * 100.0) * 0.5 + 0.5;
        float starB = exp(-sd * 50.0) * life;

        vec3 starCol = vec3(1.0);
        if (sr > 0.97) {
            starCol = soul(sr * 5.0 + t * 0.2);
            float pulseBr = pow(sin(t * 3.0 + sr * 50.0) * 0.5 + 0.5, 2.0);
            col += starCol * starB * (1.0 + pulseBr * 2.0) * 0.8;
        } else {
            col += starCol * starB * 0.4;
        }
    }

    // === RIVER OF LIGHT ===
    float ry = sin(p.x * 2.0 + t) * 0.3 + sin(p.x * 3.0 - t * 0.7) * 0.15;
    float rd = abs(p.y - ry);
    float rw = 0.08 + sin(p.x * 5.0 + t * 2.0) * 0.03;
    float river = smoothstep(rw, 0.0, rd);

    vec2 puv = vec2(p.x * 10.0 + t * 3.0, p.y * 10.0);
    float pn = noise(puv);
    float particles = river * pn * pn;

    col += dreamColor(p.x + t * 0.2, t) * (river * 0.3 + particles * 0.4);

    // === CENTRAL EYE ===
    float eyePulse = sin(t * 0.7) * 0.1;
    float ed = length(p);

    for (float i = 0.0; i < 4.0; i++) {
        float rr = 0.15 + i * 0.08 + eyePulse;
        float ring = smoothstep(0.02, 0.0, abs(ed - rr));
        col += soul(i * 0.25 + t * 0.15) * ring * 0.4;
    }

    float pupil = smoothstep(0.08, 0.02, ed);
    col = mix(col, vec3(0.0), pupil * 0.8);

    vec2 hlPos = vec2(-0.03, 0.03);
    float hl = exp(-length(p - hlPos) * 80.0);
    col += vec3(0.8, 0.9, 1.0) * hl * 0.6;

    // === FIBONACCI SPIRAL ===
    float sa = atan(p.y, p.x);
    float sr2 = length(p);
    float gs = abs(fract(log(sr2) / log(PHI) - sa / TAU + t * 0.1) - 0.5);
    float spLine = exp(-gs * 30.0) * smoothstep(0.8, 0.2, sr2);
    col += soul(sr2 + t * 0.2) * spLine * 0.25;

    // === OLED PROTECTION ===
    float voidBreath = fbm(p * 1.5 + t * 0.15, 4);
    float darkness = smoothstep(0.3, 0.6, voidBreath);
    col *= 0.4 + darkness * 0.6;

    float vd = length(p);
    float vig = 1.0 - smoothstep(0.3, 1.1, vd * 0.7);
    vig = pow(vig, 1.5);
    col *= vig;

    float edge = smoothstep(0.0, 0.35, 1.0 - max(abs(p.x) * 0.6, abs(p.y) * 0.7));
    col *= edge;

    // === FINAL ===
    col *= 0.7 + breath * 0.2 + heartbeat * 0.1;

    float moodShift = sin(t * 0.1) * 0.1;
    col.r *= 1.0 + moodShift;
    col.b *= 1.0 - moodShift * 0.5;

    col = pow(col, vec3(0.95));
    col = min(col, vec3(0.85));
    col = max(col - 0.02, vec3(0.0));

    fragColor = vec4(col, 1.0);
}
