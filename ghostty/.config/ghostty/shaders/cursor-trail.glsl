// Vệt sáng theo con trỏ: khi con trỏ nhảy từ vị trí cũ sang mới, một vệt thon dần
// (đầu to ở con trỏ mới, đuôi nhọn) co về phía con trỏ trong ~0.2s rồi tan.
// Tọa độ Ghostty: gốc dưới-trái như Shadertoy, iCurrentCursor.xy là góc trên-trái của con trỏ.

const float DURATION = 0.22;

float sdTaperedSegment(vec2 p, vec2 a, vec2 b, float ra, float rb) {
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / max(dot(ba, ba), 1e-6), 0.0, 1.0);
    return length(pa - ba * h) - mix(ra, rb, h);
}

vec2 cursorCenter(vec4 c) {
    return c.xy + vec2(c.z * 0.5, -c.w * 0.5);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 term = texture(iChannel0, fragCoord / iResolution.xy);
    fragColor = term;

    // Không vẽ khi mất focus (tránh frame lẻ làm vệt nhảy) hoặc khi chưa có vị trí cũ
    if (iFocus == 0 || iPreviousCursor.z <= 0.0 || iPreviousCursor.w <= 0.0) return;

    float t = (iTime - iTimeCursorChange) / DURATION;
    if (t >= 1.0) return;
    t = max(t, 0.0);

    vec2 head = cursorCenter(iCurrentCursor);
    vec2 start = cursorCenter(iPreviousCursor);
    if (distance(head, start) < 1.0) return;

    float eased = 1.0 - pow(1.0 - t, 3.0);      // easeOutCubic: đuôi lao nhanh rồi chậm dần
    vec2 tail = mix(start, head, eased);

    float headR = iCurrentCursor.w * 0.24;
    float d = sdTaperedSegment(fragCoord, tail, head, headR * 0.12, headR);

    float fade = 1.0 - t;
    float core = smoothstep(1.5, -1.5, d) * fade * 0.55;
    float glow = exp(-max(d, 0.0) / (iCurrentCursor.w * 0.55)) * fade * 0.12;

    fragColor.rgb = mix(term.rgb, iCurrentCursorColor.rgb, clamp(core + glow, 0.0, 1.0));
}
