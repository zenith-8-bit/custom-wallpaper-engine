#version 330 core

uniform float iTime;
uniform vec3 iResolution;

out vec4 fragColor;


// ============================================================
// NEBULAWALL ADAPTATION
// Original shader:
// "another synthwave sunset thing"
// Shadertoy ID: tsScRK
//
// Adapted for:
// OpenGL 3.3 / ModernGL / NebulaWall
//
// Audio texture sampling is intentionally disabled because
// NebulaWall currently does not provide Shadertoy iChannel0.
// ============================================================


//#define AA 4
//#define VAPORWAVE
//#define stereo 1. // -1. for cross-eyed
#define speed 10.
#define wave_thing
//#define city

#define disable_sound_texture_sampling

#define audio_vibration_amplitude .125


// Shadertoy provides iTimeDelta.
// NebulaWall currently doesn't, so use a stable 60 FPS value.
const float iTimeDelta = 1.0 / 60.0;


float jTime;


// ============================================================
// TEXTURE MIRROR
// ============================================================

#ifdef disable_sound_texture_sampling

#define textureMirror(a, b) vec4(0.0)

#else

vec4 textureMirror(sampler2D tex, vec2 c)
{
    vec2 cf = fract(c);

    return texture(
        tex,
        mix(
            cf,
            1.0 - cf,
            mod(floor(c), 2.0)
        )
    );
}

#endif


// ============================================================
// MATH / NOISE
// ============================================================

float amp(vec2 p)
{
    return smoothstep(1.0, 8.0, abs(p.x));
}


float pow512(float a)
{
    a *= a; // ^2
    a *= a; // ^4
    a *= a; // ^8
    a *= a; // ^16
    a *= a; // ^32
    a *= a; // ^64
    a *= a; // ^128
    a *= a; // ^256

    return a * a; // ^512
}


float pow1d5(float a)
{
    return a * sqrt(a);
}


float hash21(vec2 co)
{
    return fract(
        sin(dot(co.xy, vec2(1.9898, 7.233)))
        * 45758.5433
    );
}


float hash(vec2 uv)
{
    float a = amp(uv);

#ifdef wave_thing

    float w =
        a > 0.0
        ?
        (
            1.0
            -
            0.4
            *
            pow512(
                0.51
                +
                0.49
                *
                sin(
                    (
                        0.02 * (uv.y + 0.5 * uv.x)
                        - jTime
                    ) * 2.0
                )
            )
        )
        :
        0.0;

#else

    float w = 1.0;

#endif


    return
        (
            a > 0.0
            ?
            a * pow1d5(
                hash21(uv)
            ) * w
            :
            0.0
        )
        -
        (
            textureMirror(
                iChannel0,
                vec2(
                    (uv.x * 29.0 + uv.y) * 0.03125,
                    1.0
                )
            ).x
            * audio_vibration_amplitude
        );
}


// ============================================================
// TERRAIN EDGE
// ============================================================

float edgeMin(
    float dx,
    vec2 da,
    vec2 db,
    vec2 uv
)
{
    uv.x += 5.0;

    vec3 c =
        fract(
            round(
                vec3(
                    uv,
                    uv.x + uv.y
                )
            )
            *
            (
                vec3(0.0, 1.0, 2.0)
                +
                0.61803398875
            )
        );


    float a1 =
        textureMirror(
            iChannel0,
            vec2(c.y, 0.0)
        ).x > 0.6
        ?
        0.15
        :
        1.0;


    float a2 =
        textureMirror(
            iChannel0,
            vec2(c.x, 0.0)
        ).x > 0.6
        ?
        0.15
        :
        1.0;


    float a3 =
        textureMirror(
            iChannel0,
            vec2(c.z, 0.0)
        ).x > 0.6
        ?
        0.15
        :
        1.0;


    return min(
        min(
            (1.0 - dx) * db.y * a3,
            da.x * a2
        ),
        da.y * a1
    );
}


// ============================================================
// TRIANGULAR NOISE
// ============================================================

vec2 trinoise(vec2 uv)
{
    const float sq = sqrt(3.0 / 2.0);

    uv.x *= sq;
    uv.y -= 0.5 * uv.x;

    vec2 d = fract(uv);

    uv -= d;

    bool c = dot(d, vec2(1.0)) > 1.0;

    vec2 dd = 1.0 - d;

    vec2 da = c ? dd : d;
    vec2 db = c ? d : dd;


    float nn =
        hash(
            uv + float(c)
        );


    float n2 =
        hash(
            uv + vec2(1.0, 0.0)
        );


    float n3 =
        hash(
            uv + vec2(0.0, 1.0)
        );


    float nmid =
        mix(
            n2,
            n3,
            d.y
        );


    float ns =
        mix(
            nn,
            c ? n2 : n3,
            da.y
        );


    float dx =
        da.x / db.y;


    return vec2(
        mix(
            ns,
            nmid,
            dx
        ),
        edgeMin(
            dx,
            da,
            db,
            uv + d
        )
    );
}


// ============================================================
// TERRAIN
// ============================================================

vec2 map(vec3 p)
{
    vec2 n =
        trinoise(
            p.xz
        );


    return vec2(
        p.y - 2.0 * n.x,
        n.y
    );
}


// ============================================================
// TERRAIN NORMAL
// ============================================================

vec3 grad(vec3 p)
{
    const vec2 e =
        vec2(
            0.005,
            0.0
        );


    float a =
        map(p).x;


    return vec3(
        map(p + e.xyy).x - a,
        map(p + e.yxy).x - a,
        map(p + e.yyx).x - a
    )
    /
    e.x;
}


// ============================================================
// RAY / TERRAIN INTERSECTION
// ============================================================

vec2 intersect(
    vec3 ro,
    vec3 rd
)
{
    float d = 0.0;
    float h = 0.0;


    for(int i = 0; i < 500; i++)
    {
        vec3 p =
            ro + d * rd;


        vec2 s =
            map(p);


        h =
            s.x;


        d += h * 0.5;


        if(abs(h) < 0.003 * d)
        {
            return vec2(
                d,
                s.y
            );
        }


        if(
            d > 150.0
            ||
            p.y > 2.0
        )
        {
            break;
        }
    }


    return vec2(-1.0);
}


// ============================================================
// SUN
// ============================================================

void addsun(
    vec3 rd,
    vec3 ld,
    inout vec3 col
)
{
    float sun =
        smoothstep(
            0.21,
            0.2,
            distance(rd, ld)
        );


    if(sun > 0.0)
    {
        float yd =
            rd.y - ld.y;


        float a =
            sin(
                3.1 *
                exp(
                    -(yd) * 14.0
                )
            );


        sun *=
            smoothstep(
                -0.8,
                0.0,
                a
            );


        col =
            mix(
                col,
                vec3(
                    1.0,
                    0.8,
                    0.4
                ) * 0.75,
                sun
            );
    }
}


// ============================================================
// STAR FIELD
// ============================================================

float starnoise(vec3 rd)
{
    float c = 0.0;

    vec3 p =
        normalize(rd)
        * 300.0;


    for(float i = 0.0; i < 4.0; i++)
    {
        vec3 q =
            fract(p)
            - 0.5;


        vec3 id =
            floor(p);


        float c2 =
            smoothstep(
                0.5,
                0.0,
                length(q)
            );


        c2 *=
            step(
                hash21(
                    id.xz / id.y
                ),
                0.06 - i * i * 0.005
            );


        c += c2;


        p =
            p * 0.6
            +
            0.5
            *
            p
            *
            mat3(
                 3.0 / 5.0, 0.0,        4.0 / 5.0,
                 0.0,       1.0,        0.0,
                -4.0 / 5.0, 0.0,        3.0 / 5.0
            );
    }


    c *= c;


    float g =
        dot(
            sin(rd * 10.512),
            cos(rd.yzx * 10.512)
        );


    c *=
        smoothstep(
            -3.14,
            -0.9,
            g
        )
        * 0.5
        +
        0.5
        *
        smoothstep(
            -0.3,
            1.0,
            g
        );


    return c * c;
}


// ============================================================
// SKY
// ============================================================

vec3 gsky(
    vec3 rd,
    vec3 ld,
    bool mask
)
{
    float haze =
        exp2(
            -5.0
            *
            (
                abs(rd.y)
                -
                0.2 * dot(rd, ld)
            )
        );


    float st =
        mask
        ?
        (
            starnoise(rd)
            *
            (
                1.0
                -
                min(haze, 1.0)
            )
        )
        :
        0.0;


    vec3 back =
        vec3(
            0.4,
            0.1,
            0.7
        )
        *
        (
            1.0
            -
            0.5
            *
            textureMirror(
                iChannel0,
                vec2(
                    0.5
                    +
                    0.05 * rd.x / rd.y,
                    0.0
                )
            ).x
            *
            exp2(
                -0.1
                *
                abs(
                    length(rd.xz) / rd.y
                )
            )
            *
            max(
                sign(rd.y),
                0.0
            )
        );


#ifdef city

    float x =
        round(
            rd.x * 30.0
        );


    float h =
        hash21(
            vec2(
                x - 166.0
            )
        );


    bool building =
        (
            h * h
            * 0.125
            * exp2(
                -x * x * x * x * 0.0025
            )
            >
            rd.y
        );


    if(mask && building)
    {
        back *= 0.0;

        haze = 0.8;

        mask =
            mask
            &&
            !building;
    }

#endif


    vec3 col =
        clamp(
            mix(
                back,
                vec3(
                    0.7,
                    0.1,
                    0.4
                ),
                haze
            )
            +
            st,
            0.0,
            1.0
        );


    if(mask)
    {
        addsun(
            rd,
            ld,
            col
        );
    }


    return col;
}


// ============================================================
// SHADER ENTRY
// ============================================================

void mainImage(
    out vec4 fragColor,
    in vec2 fragCoord
)
{
    fragColor =
        vec4(0.0);


#ifdef AA

    for(
        float x = 0.0;
        x < 1.0;
        x += 1.0 / float(AA)
    )
    {
        for(
            float y = 0.0;
            y < 1.0;
            y += 1.0 / float(AA)
        )
        {

#else

        const float AA = 1.0;
        const float x = 0.0;
        const float y = 0.0;

#endif


        vec2 uv =
            (
                2.0
                *
                (
                    fragCoord
                    +
                    vec2(x, y)
                )
                -
                iResolution.xy
            )
            /
            iResolution.y;


        const float shutter_speed =
            0.25;


        float dt =
            fract(
                hash21(
                    float(AA)
                    *
                    (
                        fragCoord
                        +
                        vec2(x, y)
                    )
                )
                +
                iTime
            )
            *
            shutter_speed;


        jTime =
            mod(
                iTime
                -
                dt * iTimeDelta,
                4000.0
            );


        vec3 ro =
            vec3(
                0.0,
                1.0,
                -20000.0
                +
                jTime * speed
            );


#ifdef stereo

        ro +=
            stereo
            *
            vec3(
                0.2
                *
                (
                    float(uv.x > 0.0)
                    -
                    0.5
                ),
                0.0,
                0.0
            );


        const float de = 0.9;


        uv.x =
            uv.x
            +
            0.5
            *
            (
                uv.x > 0.0
                ?
                -de
                :
                de
            );


        uv *= 2.0;

#endif


        vec3 rd =
            normalize(
                vec3(
                    uv,
                    4.0 / 3.0
                )
            );


        vec2 hit =
            intersect(
                ro,
                rd
            );


        float d =
            hit.x;


        vec3 ld =
            normalize(
                vec3(
                    0.0,
                    0.125
                    +
                    0.05
                    *
                    sin(
                        0.1 * jTime
                    ),
                    1.0
                )
            );


        vec3 fog =
            d > 0.0
            ?
            exp2(
                -d
                *
                vec3(
                    0.14,
                    0.1,
                    0.28
                )
            )
            :
            vec3(0.0);


        vec3 sky =
            gsky(
                rd,
                ld,
                d < 0.0
            );


        vec3 p =
            ro
            +
            d * rd;


        vec3 n =
            normalize(
                grad(p)
            );


        float diff =
            dot(n, ld)
            +
            0.1 * n.y;


        vec3 col =
            vec3(
                0.1,
                0.11,
                0.18
            )
            *
            diff;


        vec3 rfd =
            reflect(
                rd,
                n
            );


        vec3 rfcol =
            gsky(
                rfd,
                ld,
                true
            );


        col =
            mix(
                col,
                rfcol,
                0.05
                +
                0.95
                *
                pow(
                    max(
                        1.0
                        +
                        dot(rd, n),
                        0.0
                    ),
                    5.0
                )
            );


#ifdef VAPORWAVE

        col =
            mix(
                col,
                vec3(
                    0.4,
                    0.5,
                    1.0
                ),
                smoothstep(
                    0.05,
                    0.0,
                    hit.y
                )
            );


        col =
            mix(
                sky,
                col,
                fog
            );


        col =
            sqrt(col);

#else

        col =
            mix(
                col,
                vec3(
                    0.8,
                    0.1,
                    0.92
                ),
                smoothstep(
                    0.05,
                    0.0,
                    hit.y
                )
            );


        col =
            mix(
                sky,
                col,
                fog
            );

#endif


        if(d < 0.0)
        {
            d = 1e6;
        }


        d =
            min(
                d,
                10.0
            );


        fragColor +=
            vec4(
                clamp(
                    col,
                    0.0,
                    1.0
                ),
                0.1
                +
                exp2(-d)
            );


#ifdef AA

        }
    }


    fragColor /=
        float(AA * AA);

#endif
}


// ============================================================
// OPENGL ENTRY POINT
// ============================================================

void main()
{
    mainImage(
        fragColor,
        gl_FragCoord.xy
    );
}