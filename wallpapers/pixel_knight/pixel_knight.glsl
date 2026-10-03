#version 330 core

uniform float iTime;
uniform vec3 iResolution;

out vec4 fragColor;

const float ECHELLE = 3.0;

bool bx(vec2 l, float x0, float y0, float x1, float y1)
{
    return l.x >= x0 && l.x <= x1 && l.y >= y0 && l.y <= y1;
}

float distSegment(vec2 p, vec2 a, vec2 b)
{
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}

vec4 pixelHeros(
    vec2 l,
    float z,
    float fr,
    float enAir,
    float st,
    float sp,
    float clin
)
{
    vec4 c = vec4(0.0);

    float face = (z > 1.5) ? 1.0 : 0.0;
    float rebond = (enAir < 0.5 && (fr == 1.0 || fr == 3.0)) ? 1.0 : 0.0;

    vec2 u = vec2(l.x, l.y - rebond);

    float gardeVisible =
        (st < -0.5) ? 0.0 :
        ((st < 0.5 ||
          (st < 1.5 && sp < 0.12) ||
          (st > 4.5 && sp > 0.88)) ? 1.0 : 0.0);

    if (distSegment(u, vec2(-4.0, 5.0), vec2(-11.0, 1.0)) < 0.8)
        c = vec4(0.35, 0.22, 0.14, 0.6);

    if (length(u - vec2(-11.0, 1.0)) < 1.0)
        c = vec4(0.90, 0.70, 0.30, 0.6);

    if (gardeVisible > 0.5)
    {
        if (bx(u, -4.0, 6.0, -4.0, 7.0))
            c = vec4(0.50, 0.30, 0.20, 0.6);

        if (bx(u, -5.0, 5.0, -3.0, 5.0))
            c = vec4(0.95, 0.75, 0.30, 0.6);

        if (bx(u, -4.0, 8.0, -4.0, 8.0))
            c = vec4(0.95, 0.75, 0.30, 0.6);
    }

    float la =
        (enAir > 0.5 || fr == 0.0) ? 3.0 :
        ((fr == 2.0) ? -3.0 : 0.0);

    float lb = -la;

    float jambeY0 = (enAir > 0.5) ? 1.0 : 0.0;

    vec3 botte = vec3(0.42, 0.26, 0.16);
    vec3 pantalon = vec3(0.22, 0.28, 0.50);

    if (bx(l, lb - 1.0, jambeY0, lb, jambeY0 + 3.0))
        c = vec4(
            (l.y - jambeY0 < 2.0) ? botte * 0.8 : pantalon * 0.8,
            0.8
        );

    if (bx(l, la - 1.0, jambeY0, la, jambeY0 + 3.0))
        c = vec4(
            (l.y - jambeY0 < 2.0) ? botte : pantalon,
            0.8
        );

    if (bx(u, -3.0, 4.0, 3.0, 8.0))
    {
        vec3 tn = vec3(0.20, 0.38, 0.80) *
                  (0.85 + 0.3 * step(0.0, u.x));

        if (abs(u.y - 5.0) < 0.5)
            tn = vec3(0.62, 0.42, 0.16);

        if (abs(u.y - 5.0) < 0.5 && abs(u.x) < 0.5)
            tn = vec3(0.95, 0.80, 0.30);

        c = vec4(tn, 1.0);
    }

    if (bx(u, -3.0, 8.0, 5.0, 11.0))
    {
        vec3 hd = vec3(0.97, 0.90, 0.78);

        if (abs(u.y - 8.0) < 0.5)
            hd = vec3(0.82, 0.72, 0.60);

        c = vec4(hd, 1.0);
    }

    if (face > 0.5)
    {
        if (clin < 0.5)
        {
            if (bx(u, 0.0, 9.0, 1.0, 11.0) ||
                bx(u, 3.0, 9.0, 4.0, 11.0))
                c = vec4(0.08, 0.05, 0.12, 1.0);

            if (bx(u, 0.0, 11.0, 0.0, 11.0) ||
                bx(u, 3.0, 11.0, 3.0, 11.0))
                c = vec4(1.0);
        }
        else
        {
            if (bx(u, 0.0, 9.0, 1.0, 9.0) ||
                bx(u, 3.0, 9.0, 4.0, 9.0))
                c = vec4(0.08, 0.05, 0.12, 1.0);
        }

        if (bx(u, -1.0, 9.0, -1.0, 9.0) ||
            bx(u, 5.0, 9.0, 5.0, 9.0))
            c = vec4(1.0, 0.60, 0.65, 1.0);

        if (bx(u, 2.0, 8.0, 2.0, 8.0))
            c = vec4(0.60, 0.25, 0.30, 1.0);
    }

    if (gardeVisible > 0.5)
    {
        if (bx(u, 3.0, 5.0, 5.0, 6.0))
            c = vec4(0.70, 0.50, 0.30, 0.6);
    }

    vec2 cq = (u - vec2(0.0, 17.0)) / vec2(8.6, 5.6);

    if (dot(cq, cq) < 1.0 && u.y >= 12.0)
    {
        vec3 cp = mix(
            vec3(0.55, 0.08, 0.25),
            vec3(0.95, 0.30, 0.45),
            clamp((u.y - 12.0) / 10.0, 0.0, 1.0)
        );

        if (u.y < 13.0)
            cp = vec3(0.40, 0.06, 0.20);

        vec2 s1 = u - vec2(-4.0, 19.0);
        vec2 s2 = u - vec2(3.0, 20.0);
        vec2 s3 = u - vec2(0.0, 15.0);
        vec2 s4 = u - vec2(6.0, 16.0);

        if (dot(s1, s1) < 3.2 ||
            dot(s2, s2) < 2.6 ||
            dot(s3, s3) < 1.5 ||
            dot(s4, s4) < 1.1)
            cp = vec3(0.99, 0.95, 0.85);

        c = vec4(cp, 0.8);
    }

    if (gardeVisible < 0.5 && st > -0.5)
    {
        float pp = sp;
        vec2 poigne = vec2(5.5, 7.5);
        float angle = radians(35.0);

        if (st < 1.5)
        {
            poigne = mix(
                vec2(-4.0, 7.0),
                vec2(5.5, 7.5),
                pp
            ) + vec2(0.0, 6.0 * sin(pp * 3.14159));

            angle = mix(
                radians(210.0),
                radians(35.0),
                pp
            );
        }
        else if (st < 2.5)
        {
            angle = radians(35.0);
        }
        else if (st < 3.5)
        {
            float a1 = radians(35.0);
            float a2 = radians(115.0);
            float a3 = radians(-45.0);

            angle =
                (sp < 0.3)
                ? mix(a1, a2, sp / 0.3)
                : mix(
                    a2,
                    a3,
                    smoothstep(0.0, 1.0, (sp - 0.3) / 0.7)
                );
        }
        else if (st < 4.5)
        {
            angle = mix(
                radians(-45.0),
                radians(35.0),
                smoothstep(0.0, 1.0, sp)
            );
        }
        else
        {
            pp = 1.0 - sp;

            poigne = mix(
                vec2(-4.0, 7.0),
                vec2(5.5, 7.5),
                pp
            ) + vec2(0.0, 6.0 * sin(pp * 3.14159));

            angle = mix(
                radians(210.0),
                radians(35.0),
                pp
            );
        }

        vec2 direction = vec2(cos(angle), sin(angle));
        vec2 perpendiculaire = vec2(-direction.y, direction.x);

        if (distSegment(u, vec2(3.0, 7.0), poigne) < 0.8)
            c = vec4(0.80, 0.70, 0.58, 0.8);

        if (distSegment(u, poigne - direction * 2.0, poigne) < 0.6)
            c = vec4(0.45, 0.28, 0.18, 0.6);

        if (length(u - (poigne - direction * 2.5)) < 0.8)
            c = vec4(0.95, 0.75, 0.30, 0.6);

        if (distSegment(
            u,
            poigne + direction * 0.8 - perpendiculaire * 2.2,
            poigne + direction * 0.8 + perpendiculaire * 2.2
        ) < 0.6)
            c = vec4(0.95, 0.75, 0.30, 0.6);

        float db = distSegment(
            u,
            poigne + direction * 1.5,
            poigne + direction * 9.5
        );

        if (db < 0.75)
            c = vec4(
                mix(
                    vec3(0.62, 0.70, 0.88),
                    vec3(0.95, 0.97, 1.0),
                    step(db, 0.35)
                ),
                0.6
            );

        if (length(u - (poigne + direction * 9.5)) < 1.0)
            c = vec4(1.0, 1.0, 1.0, 0.6);
    }

    return c;
}

const int NP = 16;

const float DUREES[NP] = float[NP](
    2.0, 2.0, 2.0, 2.0,
    2.0, 2.0, 2.0, 2.0,
    2.0, 2.0, 2.0, 2.0,
    2.0, 2.5, 7.0, 3.0
);

float alea(float n)
{
    return fract(sin(n * 91.3458) * 47453.5453);
}

float hash21(vec2 p)
{
    return fract(
        sin(dot(p, vec2(12.9898, 78.233))) *
        43758.5453
    );
}

vec2 mainPour(vec2 cible, vec2 pivot, float incl)
{
    if (pivot.y < 0.5 && abs(incl) < 0.35)
        return vec2(
            cible.x + floor(incl * cible.y + 0.5),
            cible.y
        );

    vec2 d = cible - pivot;

    float cs = cos(incl);
    float sn = sin(incl);

    return pivot + vec2(
        cs * d.x + sn * d.y,
        -sn * d.x + cs * d.y
    );
}

vec4 pixelEpee(vec2 u, vec2 poigne, float angle)
{
    vec4 c = vec4(0.0);

    vec2 direction = vec2(cos(angle), sin(angle));
    vec2 perpendiculaire = vec2(-direction.y, direction.x);

    if (distSegment(u, poigne - direction * 2.0, poigne) < 0.6)
        c = vec4(0.45, 0.28, 0.18, 1.0);

    if (length(u - (poigne - direction * 2.5)) < 0.8)
        c = vec4(0.95, 0.75, 0.30, 1.0);

    if (distSegment(
        u,
        poigne + direction * 0.8 - perpendiculaire * 2.2,
        poigne + direction * 0.8 + perpendiculaire * 2.2
    ) < 0.6)
        c = vec4(0.95, 0.75, 0.30, 1.0);

    float db = distSegment(
        u,
        poigne + direction * 1.5,
        poigne + direction * 9.5
    );

    if (db < 0.75)
        c = vec4(
            mix(
                vec3(0.62, 0.70, 0.88),
                vec3(0.95, 0.97, 1.0),
                step(db, 0.35)
            ),
            1.0
        );

    if (length(u - (poigne + direction * 9.5)) < 1.0)
        c = vec4(1.0);

    return c;
}

vec4 voxelHeros(
    vec3 cell,
    vec2 fp,
    float sens,
    float cs,
    float sn,
    vec2 pivot,
    float incl,
    vec2 mainPos,
    float fr,
    float enAir,
    float st,
    float sp,
    float clin
)
{
    vec2 l = cell.xy - fp;

    l.x *= sens;

    vec2 d = l - pivot;

    vec2 lr = floor(
        pivot +
        vec2(
            cs * d.x + sn * d.y,
            -sn * d.x + cs * d.y
        ) +
        0.5
    );

    if (pivot.y < 0.5 && abs(incl) < 0.35)
        lr = vec2(
            l.x + floor(incl * l.y + 0.5),
            l.y
        );

    if (
        lr.x < -14.0 ||
        lr.x > 18.0 ||
        lr.y < -2.0 ||
        lr.y > 27.0
    )
        return vec4(0.0);

    vec4 c = pixelHeros(
        lr,
        cell.z,
        fr,
        enAir,
        st,
        sp,
        clin
    );

    if (st < -0.5)
    {
        if (distSegment(lr, vec2(3.0, 7.0), mainPos) < 0.8)
            c = vec4(0.80, 0.70, 0.58, 0.8);

        if (length(lr - mainPos) < 1.1)
            c = vec4(0.97, 0.85, 0.72, 0.8);
    }

    if (c.a < 0.5)
        return vec4(0.0);

    float demi =
        (c.a > 0.9) ? 2.0 :
        ((c.a > 0.7) ? 1.0 : 0.0);

    if (abs(cell.z) > demi)
        return vec4(0.0);

    return vec4(c.rgb, 1.0);
}

vec4 voxelEpee(
    vec3 cell,
    vec2 piedSolCell,
    float sens,
    vec4 epee
)
{
    if (abs(cell.z) > 0.5)
        return vec4(0.0);

    vec2 l = cell.xy - piedSolCell;

    l.x *= sens;

    if (
        l.x < -16.0 ||
        l.x > 26.0 ||
        l.y < -4.0 ||
        l.y > 40.0
    )
        return vec4(0.0);

    vec4 e = pixelEpee(
        l,
        epee.xy,
        epee.z
    );

    return (e.a > 0.5)
        ? vec4(e.rgb, 1.0)
        : vec4(0.0);
}

float symbole(vec2 q, float type)
{
    if (type < 0.5)
    {
        return (
            bx(q, 0.0, 2.0, 1.0, 7.0) ||
            bx(q, 0.0, 0.0, 1.0, 0.0)
        ) ? 1.0 : 0.0;
    }

    if (type < 1.5)
    {
        return (
            bx(q, 1.0, 6.0, 3.0, 6.0) ||
            bx(q, 0.0, 5.0, 0.0, 5.0) ||
            bx(q, 4.0, 5.0, 4.0, 5.0) ||
            bx(q, 4.0, 4.0, 4.0, 4.0) ||
            bx(q, 2.0, 3.0, 3.0, 3.0) ||
            bx(q, 2.0, 2.0, 2.0, 2.0) ||
            bx(q, 2.0, 0.0, 2.0, 0.0)
        ) ? 1.0 : 0.0;
    }

    return (
        bx(q, 0.0, 4.0, 3.0, 4.0) ||
        bx(q, 3.0, 3.0, 3.0, 3.0) ||
        bx(q, 2.0, 2.0, 2.0, 2.0) ||
        bx(q, 1.0, 1.0, 1.0, 1.0) ||
        bx(q, 0.0, 0.0, 3.0, 0.0)
    ) ? 1.0 : 0.0;
}

vec2 projPx(
    vec3 w,
    vec3 ro,
    vec3 fw,
    vec3 rt,
    vec3 upv,
    vec2 resF,
    out float zc
)
{
    vec3 d = w - ro;

    zc = dot(d, fw);

    vec2 q = vec2(
        dot(d, rt),
        dot(d, upv)
    ) / (max(zc, 1.0) * 0.9);

    return floor(
        q * resF.y +
        resF * 0.5
    );
}

void mainImage(
    out vec4 fragColor,
    in vec2 fragCoord
)
{
    vec2 res = vec2(96.0, 54.0);
    vec2 resF = res * ECHELLE;

    float s = min(
        iResolution.x / resF.x,
        iResolution.y / resF.y
    );

    vec2 p = floor(
        (fragCoord - 0.5 * iResolution.xy) / s +
        resF * 0.5
    );

    vec2 uv = (
        p + 0.5 - resF * 0.5
    ) / resF.y;

    float total = 0.0;

    for (int i = 0; i < NP; i++)
        total += DUREES[i];

    float T = mod(iTime, total);

    float debut = 0.0;
    int idx = 0;
    bool trouve = false;

    for (int i = 0; i < NP; i++)
    {
        if (!trouve)
        {
            if (T < debut + DUREES[i])
            {
                idx = i;
                trouve = true;
            }
            else
            {
                debut += DUREES[i];
            }
        }
    }

    float u = T - debut;

    float sens = 1.0;
    float fr = 1.0;
    float enAir = 0.0;
    float st = 0.0;
    float sp = 0.0;
    float saut = 0.0;
    float decalage = 0.0;
    float incl = 0.0;

    vec2 pivot = vec2(0.0);
    vec2 cible = vec2(5.5, 7.5);
    vec4 epee = vec4(0.0);

    float clin = step(
        mod(iTime, 2.8),
        0.12
    );

    float effet = 0.0;
    float fete = 0.0;
    float exclam = 0.0;
    float inter = 0.0;
    float zzz = 0.0;
    float sueur = 0.0;

    vec4 planteeProche =
        vec4(9.0, 10.0, -1.5708, 1.0);

    vec4 planteeLoin =
        vec4(14.0, 10.0, -1.5708, 1.0);

    if (idx == 0)
    {
        st = 2.0;
        saut = step(
            0.5,
            fract(iTime * 1.5)
        );

        if (u > 1.2 && u < 1.5)
            clin = 1.0;
    }
    else if (idx == 1)
    {
        float tau = fract(u / 0.7);

        saut = 4.0 * 14.0 * tau * (1.0 - tau);
        enAir = saut > 0.5 ? 1.0 : 0.0;

        st = 2.0;
        fete = 1.0;
    }
    else if (idx == 2)
    {
        float tau = fract(iTime * 2.0);

        saut = 4.0 * 7.0 * tau * (1.0 - tau);
        enAir = saut > 0.5 ? 1.0 : 0.0;

        sens =
            (mod(floor(iTime * 8.0), 2.0) < 0.5)
            ? 1.0
            : -1.0;

        st = 3.0;
        sp = fract(iTime * 3.0);
    }
    else if (idx == 3)
    {
        fr = 0.0;
        st = 2.0;

        effet =
            smoothstep(0.0, 0.4, u) *
            (1.0 - smoothstep(1.6, 2.0, u));

        fete = effet;

        saut =
            (u > 1.5)
            ? 2.0 * abs(sin((u - 1.5) * 12.0))
            : 0.0;
    }
    else if (idx == 4)
    {
        float d = fract(u) * 1.55 - 0.75;

        if (d < -0.35)
        {
            st = 1.0;
            sp = (d + 0.75) / 0.4;
        }
        else if (d < -0.15)
        {
            st = 2.0;
        }
        else if (d < 0.15)
        {
            st = 3.0;
            sp = (d + 0.15) / 0.3;
        }
        else if (d < 0.45)
        {
            st = 4.0;
            sp = (d - 0.15) / 0.3;
        }
        else
        {
            st = 5.0;
            sp = (d - 0.45) / 0.35;
        }

        saut =
            (d > -0.15 && d < 0.3)
            ? 3.0
            : 0.0;

        enAir = saut > 0.5 ? 1.0 : 0.0;
    }
    else if (idx == 5)
    {
        fr =
            (mod(floor(iTime * 9.0), 2.0) < 0.5)
            ? 1.0
            : 3.0;

        sens =
            (mod(floor(iTime * 1.7), 2.0) < 0.5)
            ? 1.0
            : -1.0;

        decalage =
            floor(sin(iTime * 45.0) * 1.5);

        clin =
            (mod(floor(iTime * 5.0), 2.0) < 0.5)
            ? 1.0
            : 0.0;

        sueur = 1.0;
    }
    else if (idx == 6)
    {
        fr =
            (mod(floor(iTime * 6.0), 2.0) < 0.5)
            ? 0.0
            : 2.0;

        sens =
            (mod(floor(iTime * 2.0), 2.0) < 0.5)
            ? 1.0
            : -1.0;

        saut = floor(3.0 * abs(sin(iTime * 6.0)));

        st = 2.0;
        fete = 0.6;
    }
    else if (idx == 7)
    {
        float tau = fract(u);

        saut = 4.0 * 18.0 * tau * (1.0 - tau);
        enAir = saut > 0.5 ? 1.0 : 0.0;

        incl = 6.2832 * tau;
        pivot = vec2(0.0, 11.0);

        st = 2.0;
    }
    else if (idx == 8)
    {
        fr = 0.0;
        st = -1.0;

        incl = -0.12 + 0.03 * sin(iTime * 2.0);
        cible = vec2(9.0, 10.0);
        epee = planteeProche;

        if (u > 1.2 && u < 1.5)
            clin = 1.0;
    }
    else if (idx == 9)
    {
        fr = 0.0;
        st = -1.0;

        epee = planteeLoin;

        cible = vec2(
            3.5 + 1.2 * sin(iTime * 14.0),
            13.5 + sin(iTime * 11.0)
        );

        clin = step(
            0.5,
            fract(iTime * 2.0)
        );

        inter = 1.0;
    }
    else if (idx == 10)
    {
        fr = 0.0;
        st = -1.0;

        epee = planteeLoin;

        cible = vec2(
            8.0,
            16.0 + 3.0 * sin(iTime * 14.0)
        );

        fete = 0.4;
    }
    else if (idx == 11)
    {
        fr = 0.0;
        st = -1.0;

        epee = planteeLoin;

        float pompe = abs(sin(u * 5.0));

        cible = vec2(
            6.0,
            11.0 + 8.0 * pompe
        );

        saut = floor(2.0 * pompe);
        enAir = saut > 0.5 ? 1.0 : 0.0;

        fete = 0.8;
    }
    else if (idx == 12)
    {
        float tau = fract(u);

        saut = 4.0 * 10.0 * tau * (1.0 - tau);
        enAir = saut > 0.5 ? 1.0 : 0.0;

        st = 2.0;
        clin = 0.0;

        exclam =
            (u > 0.15)
            ? 1.0
            : 0.0;
    }
    else if (idx == 13)
    {
        fr = 0.0;
        st = -1.0;

        incl = 0.1 * sin(iTime * 1.6);
        cible = vec2(9.0, 10.0);
        epee = planteeProche;

        clin = 1.0;
        zzz = 1.0;
    }
    else if (idx == 14)
    {
        fr = 0.0;

        float tf = 0.326;
        vec2 sol = vec2(8.0, 1.2);

        if (u < 1.0)
        {
            st = 2.0;

            saut = step(
                0.5,
                fract(iTime * 1.5)
            );
        }
        else
        {
            st = -1.0;

            float t = u - 1.0;

            cible = vec2(6.0, 6.5);
            clin = 0.0;

            if (t < tf)
            {
                epee = vec4(
                    5.5 + (sol.x - 5.5) * t / tf,
                    7.5 + 10.0 * t - 90.0 * t * t,
                    radians(35.0 - 395.0 * t / tf),
                    1.0
                );
            }
            else
            {
                float t2 =
                    clamp((t - tf) / 0.25, 0.0, 1.0);

                float rebond =
                    (t - tf < 0.25)
                    ? 12.0 * t2 * (1.0 - t2)
                    : 0.0;

                epee = vec4(
                    sol.x,
                    sol.y + rebond,
                    0.0,
                    1.0
                );
            }

            if (t > 0.35 && t < 0.9)
            {
                float tau = (t - 0.35) / 0.55;

                saut = 36.0 * tau * (1.0 - tau);
                enAir = saut > 0.5 ? 1.0 : 0.0;
            }

            if (t > 0.35 && t < 1.6)
                exclam = 1.0;

            if (t >= 0.9 && t < 1.8)
            {
                cible = vec2(
                    3.5 + 1.2 * sin(iTime * 14.0),
                    13.5 + sin(iTime * 11.0)
                );

                clin = step(
                    0.5,
                    fract(iTime * 2.0)
                );

                if (t > 1.0)
                    inter = 1.0;
            }

            if (t >= 1.8 && t < 3.2)
            {
                float k =
                    smoothstep(1.8, 2.8, t);

                incl = -0.7 * k;

                cible = mix(
                    vec2(3.5, 13.5),
                    vec2(7.2, 1.2),
                    k
                );
            }

            if (t >= 3.2 && t < 4.4)
            {
                float k =
                    smoothstep(3.2, 4.4, t);

                incl = -0.7 * (1.0 - k);

                vec2 poigne = mix(
                    sol,
                    vec2(5.5, 7.5),
                    k
                );

                cible =
                    poigne -
                    vec2(0.8, 0.0) *
                    (1.0 - k);

                epee = vec4(
                    poigne,
                    radians(35.0) * k,
                    1.0
                );
            }

            if (t >= 4.4)
            {
                st = 2.0;
                epee = vec4(0.0);

                incl = 0.0;
                fete = 1.0;

                saut =
                    step(
                        0.5,
                        fract(iTime * 3.0)
                    ) * 2.0;
            }
        }
    }
    else
    {
        fr = 0.0;

        if (u < 0.35)
        {
            st = 2.0;
        }
        else if (u < 1.6833)
        {
            st = -1.0;

            float t = u - 0.35;

            cible = vec2(
                6.0,
                11.0 + 2.0 * sin(iTime * 10.0)
            );

            epee = vec4(
                5.5,
                7.5 + 60.0 * t - 45.0 * t * t,
                radians(35.0) +
                    6.2832 * 3.0 * t / 1.3333,
                1.0
            );
        }
        else
        {
            st = 2.0;
            fete = 1.0;

            saut =
                step(
                    0.5,
                    fract(iTime * 3.0)
                ) * 2.0;
        }
    }

    vec2 pied = vec2(
        48.0 + decalage,
        12.0 + saut
    );

    vec2 piedSol = vec2(48.0, 12.0);

    vec2 fp = floor(pied);

    vec2 mainPos =
        mainPour(
            cible,
            pivot,
            incl
        );

    float cs = cos(incl);
    float sn = sin(incl);

    float ang =
        iTime * 6.2831853 / 12.0;

    float elev =
        0.30 + 0.10 * sin(iTime * 0.5);

    float dist = 55.0;

    vec3 target =
        vec3(48.5, 21.0, 0.5);

    vec3 ro =
        target +
        dist *
        vec3(
            sin(ang) * cos(elev),
            sin(elev),
            cos(ang) * cos(elev)
        );

    vec3 fw =
        normalize(target - ro);

    vec3 rt =
        normalize(
            cross(
                fw,
                vec3(0.0, 1.0, 0.0)
            )
        );

    vec3 upv =
        cross(rt, fw);

    vec3 rd =
        normalize(
            fw +
            (uv.x * rt + uv.y * upv) * 0.9
        );

    rd = vec3(
        abs(rd.x) < 1e-4 ? 1e-4 : rd.x,
        abs(rd.y) < 1e-4 ? 1e-4 : rd.y,
        abs(rd.z) < 1e-4 ? 1e-4 : rd.z
    );

    vec3 inv = 1.0 / rd;

    vec3 horizon =
        vec3(0.16, 0.05, 0.22);

    float hh =
        clamp(
            rd.y * 1.6 + 0.15,
            0.0,
            1.0
        );

    vec3 col =
        mix(
            horizon,
            vec3(0.02, 0.015, 0.08),
            hh
        );

    float fe = ECHELLE * 0.6;

    vec2 sc =
        floor(
            vec2(
                atan(rd.z, rd.x) * 60.0 * fe,
                rd.y * 60.0 * fe
            )
        );

    if (
        hash21(sc) >
        1.0 - 0.008 / (fe * fe) &&
        rd.y > 0.03
    )
    {
        col +=
            vec3(0.8, 0.75, 0.9) *
            (0.4 + 0.6 * hash21(sc + 7.0));
    }

    if (effet > 0.0)
    {
        vec2 d =
            uv * res.y +
            vec2(0.0, 3.0);

        float a2 =
            atan(d.y, d.x);

        float rayon =
            step(
                0.5,
                fract(
                    a2 * 2.5 / 3.14159 +
                    iTime * 0.15
                )
            );

        col +=
            vec3(1.0, 0.75, 0.3) *
            0.22 *
            rayon *
            effet *
            (1.0 - clamp(
                length(d) / 60.0,
                0.0,
                1.0
            ));
    }

    float tScene = 1e9;

    if (rd.y < 0.0)
    {
        float tSol =
            (12.0 - ro.y) * inv.y;

        tScene = tSol;

        vec3 hp =
            ro + rd * tSol;

        float damier =
            mod(
                floor(hp.x / 8.0) +
                floor(hp.z / 8.0),
                2.0
            );

        vec3 sol =
            vec3(0.93, 0.2, 0.45) *
            (0.55 + 0.25 * damier);

        float lx =
            min(
                mod(hp.x, 8.0),
                8.0 - mod(hp.x, 8.0)
            );

        float lz =
            min(
                mod(hp.z, 8.0),
                8.0 - mod(hp.z, 8.0)
            );

        float ligne =
            smoothstep(
                0.65,
                0.3,
                min(lx, lz)
            ) *
            exp(-tSol * 0.012);

        sol =
            mix(
                sol,
                vec3(1.0, 0.5, 0.7),
                ligne
            );

        float ombre =
            exp(
                -pow(
                    length(
                        hp.xz -
                        vec2(target.x, 0.5)
                    ) /
                    (9.0 - saut * 0.3),
                    2.0
                )
            );

        sol *= 1.0 - 0.5 * ombre;

        col =
            mix(
                sol,
                horizon,
                1.0 - exp(-tSol * 0.004)
            );
    }

    vec3 bmin =
        vec3(20.0, 8.0, -3.0);

    vec3 bmax =
        vec3(77.0, 56.0, 4.0);

    vec3 t0 =
        (bmin - ro) * inv;

    vec3 t1 =
        (bmax - ro) * inv;

    vec3 tmn =
        min(t0, t1);

    vec3 tmx =
        max(t0, t1);

    float tn =
        max(
            max(tmn.x, tmn.y),
            tmn.z
        );

    float tf2 =
        min(
            min(tmx.x, tmx.y),
            tmx.z
        );

    if (tf2 > max(tn, 0.0))
    {
        float tc =
            max(tn, 0.0) + 1e-3;

        vec3 pos =
            ro + rd * tc;

        vec3 cell =
            floor(pos);

        vec3 stp =
            sign(rd);

        vec3 tDelta =
            abs(inv);

        vec3 tMax =
            (cell + max(stp, 0.0) - ro) * inv;

        vec3 nrm =
            vec3(0.0, 0.0, 1.0);

        vec2 piedSolCell =
            floor(piedSol);

        for (int i = 0; i < 170; i++)
        {
            if (
                cell.x < bmin.x ||
                cell.x >= bmax.x ||
                cell.y < bmin.y ||
                cell.y >= bmax.y ||
                cell.z < bmin.z ||
                cell.z >= bmax.z
            )
                break;

            if (tc > tScene)
                break;

            if (abs(cell.z) < 2.5)
            {
                vec4 v = vec4(0.0);

                if (epee.w > 0.5)
                {
                    v =
                        voxelEpee(
                            cell,
                            piedSolCell,
                            sens,
                            epee
                        );
                }

                if (v.a < 0.5)
                {
                    v =
                        voxelHeros(
                            cell,
                            fp,
                            sens,
                            cs,
                            sn,
                            pivot,
                            incl,
                            mainPos,
                            fr,
                            enAir,
                            st,
                            sp,
                            clin
                        );
                }

                if (v.a > 0.5)
                {
                    float lum =
                        0.7 +
                        0.3 *
                        dot(
                            nrm,
                            normalize(
                                vec3(
                                    0.35,
                                    0.8,
                                    0.5
                                )
                            )
                        );

                    col =
                        v.rgb * lum;

                    tScene = tc;

                    break;
                }
            }

            if (
                tMax.x < tMax.y &&
                tMax.x < tMax.z
            )
            {
                tc = tMax.x;
                tMax.x += tDelta.x;
                cell.x += stp.x;

                nrm =
                    vec3(
                        -stp.x,
                        0.0,
                        0.0
                    );
            }
            else if (tMax.y < tMax.z)
            {
                tc = tMax.y;
                tMax.y += tDelta.y;
                cell.y += stp.y;

                nrm =
                    vec3(
                        0.0,
                        -stp.y,
                        0.0
                    );
            }
            else
            {
                tc = tMax.z;
                tMax.z += tDelta.z;
                cell.z += stp.z;

                nrm =
                    vec3(
                        0.0,
                        0.0,
                        -stp.z
                    );
            }
        }
    }

    float dLim =
        tScene * dot(rd, fw);

    float zc;
    vec2 pb;

    if (exclam > 0.5)
    {
        pb =
            projPx(
                vec3(
                    48.5,
                    36.0 + saut,
                    0.5
                ),
                ro,
                fw,
                rt,
                upv,
                resF,
                zc
            );

        if (
            zc < dLim &&
            symbole(
                floor(
                    (p - pb) /
                    ECHELLE
                ) +
                vec2(1.0, 0.0),
                0.0
            ) > 0.5
        )
        {
            col =
                vec3(
                    1.0,
                    0.9,
                    0.2
                );
        }
    }

    if (inter > 0.5)
    {
        pb =
            projPx(
                vec3(
                    48.5,
                    36.0,
                    0.5
                ),
                ro,
                fw,
                rt,
                upv,
                resF,
                zc
            );

        if (
            zc < dLim &&
            symbole(
                floor(
                    (p - pb) /
                    ECHELLE
                ) +
                vec2(2.0, 0.0),
                1.0
            ) > 0.5
        )
        {
            col =
                vec3(
                    0.9,
                    0.95,
                    1.0
                );
        }
    }

    if (zzz > 0.5)
    {
        for (int i = 0; i < 3; i++)
        {
            float ph =
                fract(
                    iTime * 0.45 +
                    float(i) / 3.0
                );

            pb =
                projPx(
                    vec3(
                        54.0 +
                        ph * 12.0 +
                        float(i) * 2.0,
                        30.0 +
                        ph * 14.0,
                        0.5
                    ),
                    ro,
                    fw,
                    rt,
                    upv,
                    resF,
                    zc
                );

            if (
                zc < dLim &&
                ph < 0.9 &&
                symbole(
                    floor(
                        (p - pb) /
                        ECHELLE
                    ) +
                    vec2(1.0, 0.0),
                    2.0
                ) > 0.5
            )
            {
                col =
                    vec3(
                        0.6,
                        0.8,
                        1.0
                    );
            }
        }
    }

    if (sueur > 0.5)
    {
        for (int i = 0; i < 3; i++)
        {
            float ph =
                fract(
                    iTime * 1.3 +
                    float(i) * 0.33
                );

            pb =
                projPx(
                    vec3(
                        40.0 +
                        float(i) * 8.0 +
                        sin(float(i) * 5.0) * 2.0,
                        34.0 -
                        ph * 20.0,
                        (float(i) - 1.0) * 5.0
                    ),
                    ro,
                    fw,
                    rt,
                    upv,
                    resF,
                    zc
                );

            if (
                zc < dLim &&
                p.x >= pb.x &&
                p.x < pb.x + ECHELLE &&
                p.y >= pb.y &&
                p.y < pb.y + 2.0 * ECHELLE
            )
            {
                col =
                    vec3(
                        0.5,
                        0.8,
                        1.0
                    );
            }
        }
    }

    if (fete > 0.0)
    {
        for (int i = 0; i < 8; i++)
        {
            float fi = float(i);

            float ph =
                fract(
                    iTime * 0.9 +
                    alea(fi)
                );

            vec3 w =
                vec3(
                    48.0 +
                    (alea(fi + 3.0) - 0.5) * 44.0,

                    14.0 +
                    alea(fi + 7.0) * 34.0,

                    (alea(fi + 11.0) - 0.5) * 30.0
                );

            pb =
                projPx(
                    w,
                    ro,
                    fw,
                    rt,
                    upv,
                    resF,
                    zc
                );

            vec2 e =
                abs(p - pb) /
                ECHELLE;

            float taille =
                2.0 *
                sin(ph * 3.14159) *
                fete;

            if (
                zc < dLim &&
                (
                    (e.x < 0.5 && e.y < taille) ||
                    (e.y < 0.5 && e.x < taille)
                )
            )
            {
                col =
                    mix(
                        vec3(
                            1.0,
                            0.95,
                            0.6
                        ),
                        vec3(1.0),
                        step(
                            0.5,
                            alea(fi)
                        )
                    );
            }
        }
    }

    fragColor =
        vec4(col, 1.0);
}

/*
    NebulaWall entry point.

    The original Shadertoy shader uses:

        mainImage(out vec4 fragColor, in vec2 fragCoord)

    NebulaWall renders through a standard GLSL 330 fragment shader,
    so we forward gl_FragCoord into mainImage.
*/
void main()
{
    mainImage(
        fragColor,
        gl_FragCoord.xy
    );
}