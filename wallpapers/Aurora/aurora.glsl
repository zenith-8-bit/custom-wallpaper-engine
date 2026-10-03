#version 330 core
in vec2 v_uv; out vec4 fragColor;
uniform float iTime; uniform vec3 iResolution;
void main(){vec2 p=v_uv*2.0-1.0;p.x*=iResolution.x/iResolution.y;float w1=sin(p.x*3.0+iTime*.35)*.18;float w2=sin(p.x*6.0-iTime*.55)*.08;float b=exp(-pow((p.y-.25-w1-w2)*7.0,2.0));float b2=exp(-pow((p.y-.05+w1)*9.0,2.0));vec3 c=vec3(.005,.012,.035)+vec3(.05,.75,.38)*b+vec3(.12,.35,1.0)*b2*.55;fragColor=vec4(c,1.0);}
