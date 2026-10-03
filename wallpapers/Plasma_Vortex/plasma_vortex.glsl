#version 330 core
in vec2 v_uv; out vec4 fragColor; uniform float iTime; uniform vec3 iResolution;
void main(){vec2 p=v_uv*2.0-1.0;p.x*=iResolution.x/iResolution.y;float r=length(p);float a=atan(p.y,p.x);float tunnel=sin(8.0/max(r,.05)-iTime*2.0+a*3.0);float swirl=sin(a*7.0+iTime*1.3+r*12.0);float g=(.5+.5*tunnel)*(1.0-smoothstep(.7,1.35,r));vec3 c=vec3(.10,.02,.30)*g+vec3(.20,.03,.65)*g*g+vec3(.02,.15,.45)*abs(swirl)*.25;fragColor=vec4(c,1);}
