#version 330 core
in vec2 v_uv; out vec4 fragColor; uniform float iTime;
float hash21(vec2 p){p=fract(p*vec2(123.34,456.21));p+=dot(p,p+45.32);return fract(p.x*p.y);}
void main(){vec2 uv=v_uv;float x=floor(uv.x*70.0);float r=hash21(vec2(x,3.0));float head=fract(r+iTime*(.3+r*1.5)*.18);float y=fract(uv.y+head);float line=smoothstep(.025,0.0,abs(fract(y*22.0)-.5));float mask=smoothstep(.015,0.0,abs(fract(uv.x*70.0)-.5));float g=line*mask;vec3 c=vec3(.002,.004,.012)+vec3(0,.55,.9)*g+vec3(0,.15,.4)*g*2.0;fragColor=vec4(c,1);}
