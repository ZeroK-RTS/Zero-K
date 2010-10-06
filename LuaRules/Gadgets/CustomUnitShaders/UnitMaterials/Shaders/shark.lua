return {
  vertex = [[
//#define use_shadow
    uniform mat4 camera;   //ViewMatrix (gl_ModelViewMatrix is ModelMatrix!)
    uniform vec3 cameraPos;
    uniform vec3 sunPos;
    uniform vec3 sunDiffuse;
    uniform vec3 sunAmbient;
  #ifdef use_shadow
    uniform mat4 shadowMatrix;
    uniform vec4 shadowParams;
  #endif

    uniform float frame2;
    uniform vec3  speed;

    varying vec3 normal;
    varying vec3 cameraDir;
    varying vec3 teamColor;
    varying vec3 light;


    void main(void)
    {
      gl_TexCoord[0].st = gl_MultiTexCoord0.st;

      vec4 v = gl_Vertex;
      v += (1.0 + speed.z) * smoothstep(0.0,-20.0,gl_Vertex.z) * vec4(sin(radians(frame2*10.0+gl_Vertex.z*5.0)),0.0,0.0,0.0); 
      v += (1.0 + speed.z) * smoothstep(0.0,15.0,abs(gl_Vertex.x)) * smoothstep(0.0,10.0,abs(gl_Vertex.z)) * vec4(0.0,sin(radians(frame2*15.0+gl_Vertex.z*19.0))*1.2,0.0,0.0); 

      v += vec4(-speed.x*150.0,0.0,0.0,0.0) * pow((1.0-clamp((gl_Vertex.z+80.0)/100.0,0.0,1.0)),2.5);

      vec4 worldPos = gl_ModelViewMatrix * v;

      normal    = normalize(gl_NormalMatrix * gl_Normal);
      cameraDir = worldPos.xyz - cameraPos;

      teamColor = gl_TextureEnvColor[0].rgb;

      float a = max( dot(normal, sunPos), 0.0);
      light   = a * sunDiffuse + sunAmbient;

     #ifdef use_shadow
      gl_TexCoord[1] = shadowMatrix * worldPos;
      gl_TexCoord[1].st = gl_TexCoord[1].st * (inversesqrt( abs(gl_TexCoord[1].st) + shadowParams.z) + shadowParams.w) + shadowParams.xy;
     #endif

      gl_Position = gl_ProjectionMatrix * camera * worldPos;
    }
  ]],
  fragment = [[
//#define use_shadow
    uniform sampler2D textureS3o1;
    uniform sampler2D textureS3o2;
    uniform samplerCube specularMap;

  #ifdef use_shadow
    uniform sampler2DShadow shadowMap;
    uniform float shadowDensity;
    uniform vec3 sunAmbient;
  #endif

    varying vec3 normal;
    varying vec3 cameraDir;
    varying vec3 teamColor;
    varying vec3 light;

    void main(void)
    {
       gl_FragColor    = texture2D(textureS3o1, gl_TexCoord[0].st);
       vec4 extraColor = texture2D(textureS3o2, gl_TexCoord[0].st);

       vec3 reflectDir = reflect(cameraDir, normalize(normal));
       vec3 specular   = textureCube(specularMap, reflectDir).rgb;

       vec3 shade;
     #ifdef use_shadow
       float shadow = shadow2DProj(shadowMap, gl_TexCoord[1]).r;
       shadow      = 1.0 - (1.0 - shadow) * shadowDensity;
       shade       = mix(sunAmbient, light, shadow);
       specular   *= shadow;
     #else
       shade       = light;
     #endif

       gl_FragColor.rgb = mix(gl_FragColor.rgb, teamColor, gl_FragColor.a); //teamcolor
       gl_FragColor.rgb = gl_FragColor.rgb * shade + specular;
       gl_FragColor.a   = extraColor.a;
    }
  ]],
  uniformInt = {
    textureS3o1 = 0,
    textureS3o2 = 1,
    shadowMap   = 2,
    specularMap = 3,
  },
  uniform = {
    sunPos = {gl.GetSun("pos")},
    sunAmbient = {gl.GetSun("ambient" ,"unit")},
    sunDiffuse = {gl.GetSun("diffuse" ,"unit")},
    shadowDensity = {gl.GetSun("shadowDensity" ,"unit")},
    shadowParams  = {gl.GetShadowMapParams()},
  },
  uniformMatrix = {
    shadowMatrix = {gl.GetMatrixData("shadow")},
  },
}