#version 330 core
in vec2 v_uv; out vec4 fragColor; uniform float iTime; uniform vec3 iResolution;
float hash21(vec2 p){p=fract(p*vec2(123.34,456.21));p+=dot(p,p+34.45);return fract(p.x*p.y);}
void main(){vec2 p=v_uv*2.0-1.0;p.x*=iResolution.x/iResolution.y;vec3 c=vec3(.001,.002,.008);for(int l=0;l<3;l++){float sc=35.0+float(l)*20.0;vec2 g=floor(v_uv*sc);vec2 q=fract(v_uv*sc)-.5;float r=hash21(g+float(l)*17.0);float tw=.55+.45*sin(iTime*(1.0+r*3.0)+r*20.0);float sz=mix(.015,.05,r);float pt=smoothstep(sz,0.0,length(q));float vis=step(.985,r);vec3 col=mix(vec3(.35,.55,1),vec3(1,.75,.45),r);c+=col*pt*vis*tw;}fragColor=vec4(c,1);}
