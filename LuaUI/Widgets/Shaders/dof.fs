uniform sampler2D origTex;

uniform sampler2D blurTex0;
uniform sampler2D blurTex1;
uniform sampler2D blurTex2;

uniform vec3 eyePos;
uniform mat4 viewProjection;
uniform vec2 resolution;
uniform vec2 distanceLimits;

uniform int autofocus;
uniform float manualFocusDepth;
uniform float fStop;
uniform int quality;

uniform int pass;

// Circular DOF by Kleber Garcia "Kecho" - 2017
// Publication & Filter generator: https://github.com/kecho/CircularDofFilterGenerator

/** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
**/
//Main blur pass paramters
const int KERNEL_RADIUS = 5;
const int KERNEL_COUNT = 11;
const vec4 Kernel0BracketsRealXY_ImZW = vec4(-0.056556,0.920040,-0.035849,0.611305);
const vec2 Kernel0Weights_RealX_ImY = vec2(0.411259,-0.548794);
const vec4 Kernel0_RealX_ImY_RealZ_ImW[] = vec4[](
        vec4(/*XY: Non Bracketed*/0.022302,-0.035849,/*Bracketed WZ:*/0.085711,0.000000),
        vec4(/*XY: Non Bracketed*/-0.056556,-0.013273,/*Bracketed WZ:*/0.000000,0.036931),
        vec4(/*XY: Non Bracketed*/-0.023847,0.070538,/*Bracketed WZ:*/0.035552,0.174032),
        vec4(/*XY: Non Bracketed*/0.059140,0.066382,/*Bracketed WZ:*/0.125751,0.167233),
        vec4(/*XY: Non Bracketed*/0.096696,0.020687,/*Bracketed WZ:*/0.166571,0.092483),
        vec4(/*XY: Non Bracketed*/0.102454,0.000000,/*Bracketed WZ:*/0.172829,0.058643),
        vec4(/*XY: Non Bracketed*/0.096696,0.020687,/*Bracketed WZ:*/0.166571,0.092483),
        vec4(/*XY: Non Bracketed*/0.059140,0.066382,/*Bracketed WZ:*/0.125751,0.167233),
        vec4(/*XY: Non Bracketed*/-0.023847,0.070538,/*Bracketed WZ:*/0.035552,0.174032),
        vec4(/*XY: Non Bracketed*/-0.056556,-0.013273,/*Bracketed WZ:*/0.000000,0.036931),
        vec4(/*XY: Non Bracketed*/0.022302,-0.035849,/*Bracketed WZ:*/0.085711,0.000000)
);
const vec4 Kernel1BracketsRealXY_ImZW = vec4(0.000181,0.552380,0.000000,0.180493);
const vec2 Kernel1Weights_RealX_ImY = vec2(0.513282,4.561110);
const vec4 Kernel1_RealX_ImY_RealZ_ImW[] = vec4[](
        vec4(/*XY: Non Bracketed*/0.000181,0.014423,/*Bracketed WZ:*/0.000000,0.079908),
        vec4(/*XY: Non Bracketed*/0.015852,0.024540,/*Bracketed WZ:*/0.028370,0.135962),
        vec4(/*XY: Non Bracketed*/0.042831,0.026910,/*Bracketed WZ:*/0.077211,0.149093),
        vec4(/*XY: Non Bracketed*/0.072553,0.018473,/*Bracketed WZ:*/0.131019,0.102347),
        vec4(/*XY: Non Bracketed*/0.094542,0.005900,/*Bracketed WZ:*/0.170826,0.032690),
        vec4(/*XY: Non Bracketed*/0.102454,0.000000,/*Bracketed WZ:*/0.185149,0.000000),
        vec4(/*XY: Non Bracketed*/0.094542,0.005900,/*Bracketed WZ:*/0.170826,0.032690),
        vec4(/*XY: Non Bracketed*/0.072553,0.018473,/*Bracketed WZ:*/0.131019,0.102347),
        vec4(/*XY: Non Bracketed*/0.042831,0.026910,/*Bracketed WZ:*/0.077211,0.149093),
        vec4(/*XY: Non Bracketed*/0.015852,0.024540,/*Bracketed WZ:*/0.028370,0.135962),
        vec4(/*XY: Non Bracketed*/0.000181,0.014423,/*Bracketed WZ:*/0.000000,0.079908)
);
//Blur pass parameters for objects near camera
const vec4 KernelNearBracketsRealXY_ImZW = vec4(0.034624,0.050280,-0.027250,0.190460);
const vec2 KernelNearWeights_RealX_ImY = vec2(5.268909,-0.886528);
const vec4 KernelNear_RealX_ImY_RealZ_ImW[] = vec4[](
        vec4(/*XY: Non Bracketed*/0.044566,-0.027250,/*Bracketed WZ:*/0.197749,0.000000),
        vec4(/*XY: Non Bracketed*/0.042298,-0.015499,/*Bracketed WZ:*/0.152642,0.061698),
        vec4(/*XY: Non Bracketed*/0.039368,-0.007880,/*Bracketed WZ:*/0.094353,0.101698),
        vec4(/*XY: Non Bracketed*/0.036836,-0.003243,/*Bracketed WZ:*/0.044003,0.126048),
        vec4(/*XY: Non Bracketed*/0.035189,-0.000773,/*Bracketed WZ:*/0.011253,0.139018),
        vec4(/*XY: Non Bracketed*/0.034624,-0.000000,/*Bracketed WZ:*/0.000000,0.143075),
        vec4(/*XY: Non Bracketed*/0.035189,-0.000773,/*Bracketed WZ:*/0.011253,0.139018),
        vec4(/*XY: Non Bracketed*/0.036836,-0.003243,/*Bracketed WZ:*/0.044003,0.126048),
        vec4(/*XY: Non Bracketed*/0.039368,-0.007880,/*Bracketed WZ:*/0.094353,0.101698),
        vec4(/*XY: Non Bracketed*/0.042298,-0.015499,/*Bracketed WZ:*/0.152642,0.061698),
        vec4(/*XY: Non Bracketed*/0.044566,-0.027250,/*Bracketed WZ:*/0.197749,0.000000)
);

const float baseStepValMag = 1.0/540.0;
const float inFocusThreshold = 0.25 / float(KERNEL_RADIUS);
const float colorPower = 1.6;

const vec2 autofocusTestCoords[] = vec2[](
        vec2(0.42, 0.42),
        vec2(0.42, 0.58),
        vec2(0.58, 0.58),
        vec2(0.58, 0.42),
        vec2(0.62, 0.38),
        vec2(0.6, 0.55),
        vec2(0.38, 0.4),
        vec2(0.4, 0.62)
);

vec2 multComplex(vec2 p, vec2 q)
{
    return vec2(p.x*q.x-p.y*q.y, p.x*q.y+p.y*q.x);
}

vec4 get2CompFilters(int x)
{
  vec2 c0 = Kernel0_RealX_ImY_RealZ_ImW[x].xy;
  vec2 c1 = Kernel1_RealX_ImY_RealZ_ImW[x].xy;
  return vec4(c0.x, c0.y, c1.x, c1.y);
}
vec2 get1CompFilters(int x)
{
  return KernelNear_RealX_ImY_RealZ_ImW[x].xy;
}

float LinearizeDepth(vec2 uv){   
  float depthNDC = texture2D(blurTex0, uv).r;
  #if DEPTH_CLIP01
    depthNDC = 2.0 * depthNDC - 1.0;
  #endif

    float n22 = viewProjection[2][2];

    return ((abs(((1.0 + depthNDC) * (1.0 + n22))/(2.0 * (depthNDC + n22)))
      * (distanceLimits.y - distanceLimits.x)) + distanceLimits.x) / BLUR_START_DIST;
}

float GetFilterRadius(vec2 uv)
{
  return ((2.0 * texture2D(origTex, uv).a) - 1.0) * 2.0;
}

float GetEdgeNearFilterRadius(vec2 uv, vec2 stepVal)
{
  vec2 maxCoordsOffset = stepVal * 1.8 * KERNEL_RADIUS;
  float edgeRadius = min(GetFilterRadius(uv + maxCoordsOffset), GetFilterRadius(uv - maxCoordsOffset));
  float halfEdgeRadius = min(GetFilterRadius(uv + maxCoordsOffset / 2), 
                  GetFilterRadius(uv - maxCoordsOffset / 2));
  return min(edgeRadius, halfEdgeRadius);
}

vec2 GetFilterCoords(int i, vec2 uv, vec2 stepVal, float filterRadius, out float targetFilterRadius)
{
  float filterDistance = float(i)*abs(filterRadius);
  vec2 coords = uv + stepVal*filterDistance;
  targetFilterRadius = GetFilterRadius(coords);

  if (targetFilterRadius - filterRadius < -0.02 / float(KERNEL_RADIUS))
  {
    filterDistance = (float(i))*abs(targetFilterRadius);
    coords = uv + stepVal*filterDistance;
  }
  return coords;
}

float FocusThresholdMixFactor(float filterRadius)
{
  return clamp((filterRadius - inFocusThreshold) * float(KERNEL_RADIUS) * 2.0,
        0.0, 1.0);
}

void main()
{
  vec4 fragColor = vec4(0,0,0,0);
  vec2 uv = gl_TexCoord[0].st;
  vec2 stepVal = vec2(baseStepValMag * (resolution.y/resolution.x), baseStepValMag);

  if (pass == FILTER_SIZE_PASS)
  {  
    vec4 colors = texture2D(origTex, uv);
    float lum = dot(colors.rgb,vec3(0.2126,0.7152,0.0722))*0.5;
    colors = colors *(1.0 + 0.2*lum*lum*lum);
    colors = vec4(pow(colors.r, colorPower), pow(colors.g, colorPower), pow(colors.b, colorPower), colors.a);

    float depth = LinearizeDepth(uv);
    float focusDepth = manualFocusDepth;
    float aperture = 1.0/fStop;

    if (autofocus == 1)
    {
      float centerDepth = LinearizeDepth(vec2(0.5,0.5));
      focusDepth = centerDepth;
      float testFocusDepth = focusDepth;

      float minTestDepth = focusDepth;
      float maxTestDepth = focusDepth;
      float testDepth = 0.0;
      // float meanTestDepth = 0.0;
      int autofocusTestCoordCount = 8;
      for (int i = 0; i < autofocusTestCoordCount; ++i)
      {
        testDepth = LinearizeDepth(autofocusTestCoords[i]);
        minTestDepth = min(minTestDepth, testDepth);
        maxTestDepth = max(maxTestDepth, testDepth);
        // meanTestDepth += testDepth;
        testFocusDepth += testDepth / 2.0;
      }
      // meanTestDepth /= float(autofocusTestCoordCount);
      testFocusDepth /= (1.0 + float(autofocusTestCoordCount) / 2.0);

      //pull focus back a bit to bias slightly towards air units and against distant terrain
      testFocusDepth /= min(0.95 + ((testFocusDepth * 45.0) * 0.20), 1.15);
      focusDepth /= clamp(0.95 + ((focusDepth * 45.0) * 0.20), 1.0, 1.15);

      float focusSpread = maxTestDepth - minTestDepth;
      focusSpread *= 1.75 * clamp(0.85 + ((testFocusDepth * 55.0) * 0.20), 1.0, 1.5);

      float focalLength = 0.055;
      float minFStop = 1.0 * focalLength;
      // testFocusDepth *= testFocusDepth;
      float curveDepth = 10.5;
      aperture = max(1.0/(max(
          (3.3 * (testFocusDepth + focusSpread)) 
          * exp(curveDepth * (testFocusDepth + focusSpread)),
          minFStop)), 0.0) * focalLength;

      // aperture = max(1.0/(max((testFocusDepth + focusSpread) * 3.3, minFStop)) - 2.0, 0.0) 
      //         * focalLength; 
      // depth; 
    }

    float filterRadius = clamp(((depth - focusDepth) * aperture)/depth, -1.8, 1.8);

    fragColor = vec4(colors.rgb, filterRadius * 0.25 + 0.5);

    //TODO: Convert to pre-processor definition
    gl_FragData[0] = fragColor;
    if (quality == 1)
    {
      gl_FragData[1] = fragColor;
    }
  }

  else if (pass == INITIAL_BLUR_PASS)
  {
    // vec4 val = vec4(0,0,0,0);
    vec4 valR = vec4(0,0,0,0);
    vec4 valG = vec4(0,0,0,0);
    vec4 valB = vec4(0,0,0,0);
    float filterRadius = GetFilterRadius(uv);
    float targetFilterRadius = 0.0;
    int compI = 0;
    for (int i=-KERNEL_RADIUS; i <=KERNEL_RADIUS; ++i)
    {
      compI = i;
      vec2 coords = GetFilterCoords(i, uv, vec2(0.0, stepVal.y), filterRadius, targetFilterRadius);
      if (compI < -KERNEL_RADIUS) continue;

      vec4 imageTexelRGB = texture2D(origTex, coords);
      vec4 c0_c1 = get2CompFilters(compI+KERNEL_RADIUS);
      valR.xy += imageTexelRGB.r * c0_c1.xy;
      valR.zw += imageTexelRGB.r * c0_c1.zw;
      valG.xy += imageTexelRGB.g * c0_c1.xy;
      valG.zw += imageTexelRGB.g * c0_c1.zw;
      valB.xy += imageTexelRGB.b * c0_c1.xy;
      valB.zw += imageTexelRGB.b * c0_c1.zw;
    }
    gl_FragData[0] = valR;
    gl_FragData[1] = valG;
    gl_FragData[2] = valB;
  }

  else if (pass == FINAL_BLUR_PASS)
  {
    vec4 valR = vec4(0,0,0,0);
    vec4 valG = vec4(0,0,0,0);
    vec4 valB = vec4(0,0,0,0);
    float filterRadius = GetFilterRadius(uv);
    float targetFilterRadius = 0.0;
    int compI = 0;
    for (int i=-KERNEL_RADIUS; i <=KERNEL_RADIUS; ++i)
    {
      compI = i;
      vec2 coords = GetFilterCoords(i, uv, vec2(stepVal.x, 0.0), filterRadius, targetFilterRadius);
      if (compI < -KERNEL_RADIUS) continue;
      vec4 imageTexelR = texture2D(blurTex0, coords);  
      vec4 imageTexelG = texture2D(blurTex1, coords);  
      vec4 imageTexelB = texture2D(blurTex2, coords);  
      
      vec4 c0_c1 = get2CompFilters(compI+KERNEL_RADIUS);
      
      
      valR.xy += multComplex(imageTexelR.xy,c0_c1.xy);
      valR.zw += multComplex(imageTexelR.zw,c0_c1.zw);
      
      valG.xy += multComplex(imageTexelG.xy,c0_c1.xy);
      valG.zw += multComplex(imageTexelG.zw,c0_c1.zw);
      
      valB.xy += multComplex(imageTexelB.xy,c0_c1.xy);
      valB.zw += multComplex(imageTexelB.zw,c0_c1.zw);       
    }
    
    float redChannel   = dot(valR.xy,Kernel0Weights_RealX_ImY)+dot(valR.zw,Kernel1Weights_RealX_ImY);
    float greenChannel = dot(valG.xy,Kernel0Weights_RealX_ImY)+dot(valG.zw,Kernel1Weights_RealX_ImY);
    float blueChannel  = dot(valB.xy,Kernel0Weights_RealX_ImY)+dot(valB.zw,Kernel1Weights_RealX_ImY);
    // fragColor = vec4(redChannel*redChannel,greenChannel*greenChannel,blueChannel*blueChannel,
    fragColor = vec4(vec3(pow(redChannel, 1.0/colorPower),pow(greenChannel, 1.0/colorPower),pow(blueChannel, 1.0/colorPower)),
      filterRadius * 0.25 + 0.5);   
    gl_FragData[0] = fragColor;
  }

  else if (pass == INITIAL_NEAR_BLUR_PASS)
  {
    vec4 valRG = vec4(0,0,0,0);
    vec4 valBA = vec4(0,0,0,0);
    float filterRadius = min(GetFilterRadius(uv), GetEdgeNearFilterRadius(uv, stepVal));
    float targetFilterRadius = 0.0;
    int compI = 0;
    for (int i=-KERNEL_RADIUS; i <=KERNEL_RADIUS; ++i)
    {
      compI = i;
      vec2 coords = GetFilterCoords(i, uv, vec2(0.0, stepVal.y), filterRadius, targetFilterRadius);
      if (compI < -KERNEL_RADIUS) continue;

      vec4 imageTexelRGB = texture2D(origTex, coords);
      vec2 c0 = get1CompFilters(compI+KERNEL_RADIUS);
      valRG.xy += imageTexelRGB.r * c0;
      valRG.zw += imageTexelRGB.g * c0;
      valBA.xy += imageTexelRGB.b * c0;
      valBA.zw += FocusThresholdMixFactor(-targetFilterRadius) * c0;
    }
    gl_FragData[0] = valRG;
    gl_FragData[1] = valBA;
  }

  else if (pass == FINAL_NEAR_BLUR_PASS)
  {
    vec4 valR = vec4(0,0,0,0);
    vec4 valG = vec4(0,0,0,0);
    vec4 valB = vec4(0,0,0,0);
    vec4 valA = vec4(0,0,0,0);
    float filterRadius = min(GetFilterRadius(uv), GetEdgeNearFilterRadius(uv, stepVal));
    float targetFilterRadius = 0.0;
    int compI = 0;
    for (int i=-KERNEL_RADIUS; i <=KERNEL_RADIUS; ++i)
    {
      compI = i;
      vec2 coords = GetFilterCoords(i, uv, vec2(stepVal.x, 0.0), filterRadius, targetFilterRadius);
      if (compI < -KERNEL_RADIUS) continue;
      vec4 imageTexelRG = texture2D(blurTex0, coords);  
      vec4 imageTexelBA = texture2D(blurTex1, coords); 

      vec2 c0 = get1CompFilters(compI+KERNEL_RADIUS);

      valR.xy += multComplex(imageTexelRG.xy,c0);
      valG.xy += multComplex(imageTexelRG.zw,c0);
      valB.xy += multComplex(imageTexelBA.xy,c0);
      valA.xy += multComplex(imageTexelBA.zw,c0);
    }
    float redChannel   = dot(valR.xy,KernelNearWeights_RealX_ImY);
    float greenChannel = dot(valG.xy,KernelNearWeights_RealX_ImY);
    float blueChannel  = dot(valB.xy,KernelNearWeights_RealX_ImY);
    // fragColor = vec4(redChannel*redChannel,greenChannel*greenChannel,blueChannel*blueChannel,
    fragColor = vec4(vec3(pow(redChannel, 1.0/colorPower),pow(greenChannel, 1.0/colorPower),pow(blueChannel, 1.0/colorPower)),
    clamp(dot(valA.xy, KernelNearWeights_RealX_ImY), 0.0, 1.0));
    gl_FragData[0] = fragColor;
  }

  else if (pass == COMPOSITION_PASS)
  {
    vec4 blurTexAtUV = texture2D(blurTex0, uv);
    vec4 origTexAtUV = texture2D(origTex, uv);
    float filterRadius = ((2.0 * blurTexAtUV.a) - 1.0) * 2.0;
    float mixFactor = FocusThresholdMixFactor(abs(filterRadius));
    fragColor = mix(origTexAtUV, blurTexAtUV, mixFactor);
    if (quality >= 1)
    {
      vec4 nearBlurTexAtUV = texture2D(blurTex1, uv);
      float alpha = clamp(1.0 - (abs(0.5 - nearBlurTexAtUV.a) * 2.0), 0.0, 1.0);
      fragColor.rgb = mix(fragColor.rgb, nearBlurTexAtUV.rgb, alpha);
      // fragColor = vec4(alpha);
    }
    gl_FragData[0] = fragColor;
  }

}
