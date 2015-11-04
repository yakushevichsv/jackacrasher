float rnd(vec2 s);

float rnd(vec2 s)
{
    return 1.-2.*fract(sin(s.x*678.53+s.y*313.24)*87.19);
}


void main()
{
    vec2 fragCoord=v_tex_coord.xy*u_sprite_size.xy;
    vec2 p=(fragCoord.xy*2.-u_sprite_size.xy)/u_sprite_size.x;
    float col=0.;
    
    vec2 v=vec2(1E3);
    for(int c=0;c<40;c++)
    {
        vec2 center=vec2(0.,-.5);
        vec2 vc=vec2(center.x+rnd(vec2(float(c),2.23))*.5*cos(floor(rnd(vec2(float(c),4.7))*4.)*0.7854)+rnd(vec2(float(c),349.3))*.01,
                     center.y+rnd(vec2(float(c),2.23))*.5*sin(floor(rnd(vec2(float(c),4.7))*4.)*0.7854)+rnd(vec2(float(c),912.7))*.01);
        float d=abs(dot(p-v,normalize(v-vc))-dot(p-vc,normalize(v-vc)));
        if(d<3E-3)
        {
            col=clamp(2E-4/d,0.,1.);
            break;
        }
        if(length(p-vc)<length(p-v))
        {
            v=vc;
        }
    }
    
    vec4 tex= vec4(texture2D(u_texture,v_tex_coord));
    gl_FragColor=v_color_mix; //tex;//col*vec4(vec3(1.-tex.xyz),1.)+(1.-col)*tex;
}


/*void mainOld()
{
    //vec2 p=(gl_FragCoord.xy * 2.-u_sprite_size.xy)/u_sprite_size.xy;
    
    vec2 p=(v_tex_coord.xy*2.-1);
    
    
    vec2 v=vec2(1E3);
    vec2 v2=vec2(1E4);
    vec2 center=vec2(.1,-.5);
    for(int c=0;c<90;c++)
    {
        float angle=floor(rnd(vec2(float(c),387.44))*16.)*3.1415*.4-.5;
        float dist=pow(rnd(vec2(float(c),78.21)),2.)*.5;
        vec2 vc=vec2(center.x+cos(angle)*dist+rnd(vec2(float(c),349.3))*7E-3,
                     center.y+sin(angle)*dist+rnd(vec2(float(c),912.7))*7E-3);
        if(length(vc-p)<length(v-p))
        {
            v2=v;
            v=vc;
        }
        else if(length(vc-p)<length(v2-p))
        {
            v2=vc;
        }
    }
    
    float col=abs(dot(p-v,normalize(v-v2))-dot(p-v2,normalize(v-v2)))+.002*length(p-center);
    col=7E-4/col;
    if(length(v-v2)<4E-3) col=0;
    //    if(length(v-p)<4E-3)col=1E-6;
    if(col<.3) col=0.;
    
    if (col!=0)
    {
        
        vec4 tex=texture2D(u_texture,v_tex_coord.xy+rnd(v)*.02);
        gl_FragColor=col*vec4(vec3(1.-tex.xyz),1.)+(1.-col)*tex;
    }
    else {
        gl_FragColor =  vec4(0.,0.,0.,0.);
    }
}

float rnd_old(vec2 s)
{
    return 1.-2.*fract(sin(s.x*253.13+s.y*341.41)*589.19);
}*/

