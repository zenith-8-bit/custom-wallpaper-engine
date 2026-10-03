#version 330 core

in vec2 v_uv;
out vec4 fragColor;

uniform float iTime;
uniform vec3 iResolution;


// ============================================================
// RANDOM
// ============================================================

float hash21(vec2 p)
{
    p = fract(p * vec2(127.1, 311.7));
    p += dot(p, p + 31.19);
    return fract(p.x * p.y);
}


// ============================================================
// PROCEDURAL MATRIX CHARACTER
//
// Builds characters from small horizontal/vertical/diagonal
// strokes. They aren't exact Japanese glyphs, but read as
// Matrix-style digital characters.
// ============================================================

float character(vec2 p, float seed)
{
    // Character cell coordinates
    p = fract(p);

    // Slight padding
    p = (p - 0.5) * 2.0;

    float h = 0.0;
    float v = 0.0;
    float d1 = 0.0;
    float d2 = 0.0;

    // --------------------------------------------------------
    // Random character type
    // --------------------------------------------------------

    float type = floor(seed * 8.0);

    // Horizontal strokes
    float hy1 = 1.0 -
        smoothstep(
            0.07,
            0.13,
            abs(p.y + 0.55)
        );

    float hy2 = 1.0 -
        smoothstep(
            0.07,
            0.13,
            abs(p.y)
        );

    float hy3 = 1.0 -
        smoothstep(
            0.07,
            0.13,
            abs(p.y - 0.55)
        );

    // Vertical strokes
    float vx1 = 1.0 -
        smoothstep(
            0.07,
            0.13,
            abs(p.x + 0.55)
        );

    float vx2 = 1.0 -
        smoothstep(
            0.07,
            0.13,
            abs(p.x)
        );

    float vx3 = 1.0 -
        smoothstep(
            0.07,
            0.13,
            abs(p.x - 0.55)
        );

    // Diagonals
    d1 = 1.0 -
        smoothstep(
            0.06,
            0.12,
            abs(p.y - p.x)
        );

    d2 = 1.0 -
        smoothstep(
            0.06,
            0.12,
            abs(p.y + p.x)
        );


    // --------------------------------------------------------
    // Different glyph shapes
    // --------------------------------------------------------

    if (type < 1.0)
    {
        // ┐ / └ style
        h = max(hy1, hy3);
        v = vx2;
    }
    else if (type < 2.0)
    {
        // Box / Japanese-looking symbol
        h = max(hy1, hy3);
        v = max(vx1, vx3);
    }
    else if (type < 3.0)
    {
        // Cross
        h = hy2;
        v = vx2;
    }
    else if (type < 4.0)
    {
        // Broken square
        h = max(hy1, hy2);
        v = vx1;
    }
    else if (type < 5.0)
    {
        // Diagonal
        h = d1;
        v = d2;
    }
    else if (type < 6.0)
    {
        // Complex symbol
        h = max(hy1, hy3);
        v = max(vx1, vx2);
        d1 *= 0.7;
    }
    else if (type < 7.0)
    {
        // Katakana-inspired angular shape
        h = max(hy1, hy2);
        v = max(vx2, vx3);
        d2 *= 0.7;
    }
    else
    {
        // Random technical symbol
        h = max(hy1, hy3);
        v = max(vx1, vx3);
        d1 = max(d1, d2) * 0.7;
    }

    return clamp(
        max(
            max(h, v),
            max(d1, d2)
        ),
        0.0,
        1.0
    );
}


// ============================================================
// MATRIX STREAM
// ============================================================

vec3 matrixStream(
    vec2 uv,
    float column,
    float density
)
{
    float seed =
        hash21(
            vec2(
                column,
                91.37
            )
        );

    // Different speed per column
    float speed =
        mix(
            0.20,
            0.75,
            seed
        );

    // Random starting point
    float offset =
        hash21(
            vec2(
                column,
                12.71
            )
        );

    // Moving head
    float head =
        fract(
            offset +
            iTime * speed
        );

    // Stream length
    float streamLength =
        mix(
            0.15,
            0.55,
            hash21(
                vec2(
                    column,
                    71.2
                )
            )
        );

    // Distance behind head
    float distanceBehind =
        fract(
            head -
            uv.y
        );

    // Tail brightness
    float trail =
        1.0 -
        smoothstep(
            0.0,
            streamLength,
            distanceBehind
        );

    // Make tail decay smoothly
    trail *=
        exp(
            -distanceBehind *
            3.5
        );

    // Character grid
    float rows = 24.0;

    float cellY =
        floor(
            uv.y * rows
        );

    float localY =
        fract(
            uv.y * rows
        );

    // Character changes over time
    float charSeed =
        hash21(
            vec2(
                column * 7.31,
                cellY +
                floor(iTime * 2.0)
            )
        );

    float glyph =
        character(
            vec2(
                fract(uv.x * 32.0),
                localY
            ),
            charSeed
        );

    // Character brightness
    float flicker =
        0.75 +
        0.25 *
        sin(
            iTime * 5.0 +
            column * 2.7 +
            cellY
        );

    glyph *= flicker;

    // Column center
    float x =
        (column + 0.5) /
        32.0;

    float width =
        mix(
            0.006,
            0.012,
            seed
        );

    float columnMask =
        exp(
            -pow(
                (uv.x - x) /
                width,
                2.0
            )
        );

    // Head
    float headDistance =
        abs(
            uv.y - head
        );

    float headGlow =
        exp(
            -headDistance *
            headDistance *
            7000.0
        );

    // Green character rain
    vec3 green =
        vec3(
            0.05,
            1.0,
            0.18
        );

    vec3 darkGreen =
        vec3(
            0.0,
            0.22,
            0.035
        );

    vec3 result =
        mix(
            darkGreen,
            green,
            trail
        );

    result *=
        glyph *
        columnMask;

    // Bright white-green leading character
    result +=
        vec3(
            0.65,
            1.0,
            0.72
        )
        *
        headGlow *
        columnMask *
        1.8;

    return result;
}


// ============================================================
// MAIN
// ============================================================

void main()
{
    vec2 uv = v_uv;

    // Slight aspect correction
    float aspect =
        iResolution.x /
        iResolution.y;

    vec2 p =
        uv - 0.5;

    p.x *= aspect;


    // ========================================================
    // BLACK MATRIX BACKGROUND
    // ========================================================

    vec3 col =
        vec3(
            0.0,
            0.004,
            0.001
        );


    // Extremely subtle green atmospheric glow
    float atmosphere =
        exp(
            -length(p) *
            2.0
        );

    col +=
        vec3(
            0.0,
            0.008,
            0.002
        )
        *
        atmosphere;


    // ========================================================
    // BACKGROUND RAIN
    // ========================================================

    for (int i = 0; i < 32; i++)
    {
        float column =
            float(i);

        vec3 stream =
            matrixStream(
                uv,
                column,
                0.5
            );

        col +=
            stream *
            0.85;
    }


    // ========================================================
    // SECONDARY DISTANT RAIN
    // ========================================================

    for (int i = 0; i < 18; i++)
    {
        float column =
            float(i);

        float seed =
            hash21(
                vec2(
                    column,
                    300.0
                )
            );

        // Slightly offset columns
        vec2 distantUV =
            uv;

        distantUV.x +=
            seed * 0.012;

        vec3 stream =
            matrixStream(
                distantUV,
                column + 50.0,
                0.3
            );

        col +=
            stream *
            0.22;
    }


    // ========================================================
    // SUBTLE CRT SCANLINES
    // ========================================================

    float scanline =
        0.96 +
        0.04 *
        sin(
            uv.y *
            iResolution.y *
            0.75
        );

    col *=
        scanline;


    // ========================================================
    // GREEN GLOW
    // ========================================================

    float brightness =
        max(
            col.g,
            col.b
        );

    col +=
        vec3(
            0.0,
            0.08,
            0.012
        )
        *
        brightness;


    // ========================================================
    // VIGNETTE
    // ========================================================

    float vignette =
        1.0 -
        smoothstep(
            0.35,
            0.9,
            length(p)
        );

    col *=
        mix(
            0.65,
            1.0,
            vignette
        );


    // ========================================================
    // FINAL CONTRAST
    // ========================================================

    col =
        1.0 -
        exp(
            -col * 1.35
        );


    fragColor =
        vec4(
            col,
            1.0
        );
}