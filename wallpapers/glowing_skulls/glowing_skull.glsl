#version 330 core

uniform float iTime;
uniform vec3 iResolution;

out vec4 fragColor;


// ------------------------------------------------------------
// Utility
// ------------------------------------------------------------

float circle(vec2 p, vec2 center, float radius)
{
    return length(p - center) - radius;
}

float box(vec2 p, vec2 b)
{
    vec2 d = abs(p) - b;
    return length(max(d, 0.0)) +
           min(max(d.x, d.y), 0.0);
}


// ------------------------------------------------------------
// Skull shape
// ------------------------------------------------------------

float skull(vec2 p)
{
    // Main cranium
    float head = length(p - vec2(0.0, 0.12));

    float skullShape = head - 0.34;

    // Flatten the lower part
    skullShape += max(0.0, -p.y - 0.12) * 0.7;

    // Jaw
    float jaw = box(
        p - vec2(0.0, -0.22),
        vec2(0.19, 0.16)
    );

    skullShape = min(skullShape, jaw);

    return skullShape;
}


// ------------------------------------------------------------
// Eye sockets
// ------------------------------------------------------------

float eyeSocket(vec2 p, vec2 center)
{
    vec2 q = p - center;

    q.x *= 1.15;
    q.y *= 0.85;

    return length(q) - 0.095;
}


// ------------------------------------------------------------
// Nose
// ------------------------------------------------------------

float nose(vec2 p)
{
    vec2 q = p - vec2(0.0, -0.04);

    q.y *= 1.3;

    return length(q) - 0.045;
}


// ------------------------------------------------------------
// Teeth
// ------------------------------------------------------------

float teeth(vec2 p)
{
    float d = 100.0;

    for (int i = 0; i < 7; i++)
    {
        float x = (float(i) - 3.0) * 0.045;

        vec2 toothPos = vec2(
            x,
            -0.215
        );

        float tooth = box(
            p - toothPos,
            vec2(0.016, 0.055)
        );

        d = min(d, tooth);
    }

    return d;
}


// ------------------------------------------------------------
// Glow helper
// ------------------------------------------------------------

float glow(float distanceValue, float radius)
{
    return exp(-distanceValue * distanceValue / radius);
}


// ------------------------------------------------------------
// Background
// ------------------------------------------------------------

vec3 background(vec2 uv)
{
    vec3 color = vec3(0.003, 0.005, 0.012);

    // Subtle radial light behind skull
    float aura = exp(
        -length(uv * vec2(0.8, 1.0)) * 3.0
    );

    color += vec3(
        0.01,
        0.03,
        0.07
    ) * aura;

    // Moving energy behind the skull
    float energy =
        sin(uv.x * 10.0 + iTime * 0.7) *
        sin(uv.y * 8.0 - iTime * 0.4);

    color += vec3(
        0.0,
        0.01,
        0.025
    ) * energy;

    return color;
}


// ------------------------------------------------------------
// Main
// ------------------------------------------------------------

void main()
{
    vec2 uv = gl_FragCoord.xy / iResolution.xy;

    // Correct aspect ratio
    float aspect =
        iResolution.x / iResolution.y;

    vec2 p = uv - 0.5;

    p.x *= aspect;

    vec3 color = background(p);

    // --------------------------------------------------------
    // Skull
    // --------------------------------------------------------

    float skullDistance = skull(p);

    // Skull outer glow
    float skullGlow =
        glow(skullDistance, 0.012);

    color += vec3(
        0.0,
        0.35,
        1.0
    ) * skullGlow * 0.8;

    // Skull surface
    float skullMask =
        1.0 - smoothstep(
            0.0,
            0.012,
            skullDistance
        );

    // Slightly metallic skull
    vec3 skullColor =
        vec3(
            0.55,
            0.65,
            0.72
        );

    // Animated surface lighting
    float lighting =
        0.5 +
        0.5 * sin(
            p.y * 18.0 +
            iTime * 1.2
        );

    skullColor *=
        0.65 +
        lighting * 0.25;

    color += skullColor * skullMask;


    // --------------------------------------------------------
    // Eye sockets
    // --------------------------------------------------------

    float leftEye =
        eyeSocket(
            p,
            vec2(-0.115, 0.055)
        );

    float rightEye =
        eyeSocket(
            p,
            vec2(0.115, 0.055)
        );

    // Dark sockets
    float leftDark =
        1.0 -
        smoothstep(0.0, 0.012, leftEye);

    float rightDark =
        1.0 -
        smoothstep(0.0, 0.012, rightEye);

    color -= vec3(
        0.08,
        0.09,
        0.1
    ) * leftDark;

    color -= vec3(
        0.08,
        0.09,
        0.1
    ) * rightDark;


    // --------------------------------------------------------
    // Animated glowing eyes
    // --------------------------------------------------------

    float pulse =
        0.75 +
        0.25 *
        sin(iTime * 5.0);

    vec2 leftEyePos =
        p - vec2(-0.115, 0.055);

    vec2 rightEyePos =
        p - vec2(0.115, 0.055);

    float leftGlow =
        exp(
            -length(leftEyePos) * 55.0
        );

    float rightGlow =
        exp(
            -length(rightEyePos) * 55.0
        );

    vec3 eyeColor =
        vec3(
            0.0,
            0.65,
            1.0
        );

    color +=
        eyeColor *
        leftGlow *
        pulse;

    color +=
        eyeColor *
        rightGlow *
        pulse;


    // Eye beams
    float eyeBeam =
        exp(
            -abs(p.y - 0.055) * 90.0
        );

    float eyeBeamShape =
        smoothstep(
            0.0,
            0.35,
            abs(p.x)
        );

    color +=
        eyeColor *
        eyeBeam *
        eyeBeamShape *
        0.08;


    // --------------------------------------------------------
    // Nose
    // --------------------------------------------------------

    float noseDistance =
        nose(p);

    float noseMask =
        1.0 -
        smoothstep(
            0.0,
            0.01,
            noseDistance
        );

    color -= vec3(
        0.08,
        0.09,
        0.1
    ) * noseMask;


    // --------------------------------------------------------
    // Teeth
    // --------------------------------------------------------

    float toothDistance =
        teeth(p);

    float toothMask =
        1.0 -
        smoothstep(
            0.0,
            0.008,
            toothDistance
        );

    color +=
        vec3(
            0.65,
            0.75,
            0.8
        ) *
        toothMask;


    // --------------------------------------------------------
    // Scanline effect
    // --------------------------------------------------------

    float scanline =
        sin(
            gl_FragCoord.y * 1.5
        );

    color *=
        0.96 +
        scanline * 0.025;


    // --------------------------------------------------------
    // Vignette
    // --------------------------------------------------------

    float vignette =
        1.0 -
        smoothstep(
            0.25,
            0.75,
            length(uv - 0.5)
        );

    color *=
        0.65 +
        vignette * 0.35;


    // --------------------------------------------------------
    // Output
    // --------------------------------------------------------

    color = max(color, vec3(0.0));

    fragColor =
        vec4(color, 1.0);
}