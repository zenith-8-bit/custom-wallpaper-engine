#version 330 core
in vec2 v_uv; out vec4 fragColor; uniform float iTime; uniform vec3 iResolution;
void main(){vec2 p=v_uv*2.0-1.0;p.x*=iResolution.x/iResolution.y;float t=iTime*.45;float w=sin(p.x*3.2+t)*.10+sin(p.x*7.0-t*1.4)*.045+sin(p.x*14.0+t*.7)*.018;float s=p.y-w;float d=smoothstep(.75,-.65,s);vec3 c=mix(vec3(.01,.025,.07),vec3(.015,.16,.35),d);float h=exp(-abs(s+.08)*22.0);c+=vec3(.05,.55,.9)*h;c+=vec3(0,.04,.09)*sin((p.x+p.y)*9.0+t);fragColor=vec4(c,1);}
