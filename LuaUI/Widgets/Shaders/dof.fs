uniform sampler2D origTex;

uniform sampler2D blurTex0;
uniform sampler2D blurTex1;
uniform sampler2D blurTex2;

uniform vec3 eyePos;
uniform mat4 viewProjection;
uniform vec2 resolution;

// uniform float focusDepth;
// uniform float fstopFactor;

uniform int pass;
// uniform int channel;

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
const int KERNEL_RADIUS = 8;
const int KERNEL_COUNT = 17;
const vec4 Kernel0BracketsRealXY_ImZW = vec4(-0.038708,0.943062,-0.025574,0.660892);
const vec2 Kernel0Weights_RealX_ImY = vec2(0.411259,-0.548794);
const vec4 Kernel0_RealX_ImY_RealZ_ImW[] = vec4[](
        vec4(/*XY: Non Bracketed*/0.014096,-0.022658,/*Bracketed WZ:*/0.055991,0.004413),
        vec4(/*XY: Non Bracketed*/-0.020612,-0.025574,/*Bracketed WZ:*/0.019188,0.000000),
        vec4(/*XY: Non Bracketed*/-0.038708,0.006957,/*Bracketed WZ:*/0.000000,0.049223),
        vec4(/*XY: Non Bracketed*/-0.021449,0.040468,/*Bracketed WZ:*/0.018301,0.099929),
        vec4(/*XY: Non Bracketed*/0.013015,0.050223,/*Bracketed WZ:*/0.054845,0.114689),
        vec4(/*XY: Non Bracketed*/0.042178,0.038585,/*Bracketed WZ:*/0.085769,0.097080),
        vec4(/*XY: Non Bracketed*/0.057972,0.019812,/*Bracketed WZ:*/0.102517,0.068674),
        vec4(/*XY: Non Bracketed*/0.063647,0.005252,/*Bracketed WZ:*/0.108535,0.046643),
        vec4(/*XY: Non Bracketed*/0.064754,0.000000,/*Bracketed WZ:*/0.109709,0.038697),
        vec4(/*XY: Non Bracketed*/0.063647,0.005252,/*Bracketed WZ:*/0.108535,0.046643),
        vec4(/*XY: Non Bracketed*/0.057972,0.019812,/*Bracketed WZ:*/0.102517,0.068674),
        vec4(/*XY: Non Bracketed*/0.042178,0.038585,/*Bracketed WZ:*/0.085769,0.097080),
        vec4(/*XY: Non Bracketed*/0.013015,0.050223,/*Bracketed WZ:*/0.054845,0.114689),
        vec4(/*XY: Non Bracketed*/-0.021449,0.040468,/*Bracketed WZ:*/0.018301,0.099929),
        vec4(/*XY: Non Bracketed*/-0.038708,0.006957,/*Bracketed WZ:*/0.000000,0.049223),
        vec4(/*XY: Non Bracketed*/-0.020612,-0.025574,/*Bracketed WZ:*/0.019188,0.000000),
        vec4(/*XY: Non Bracketed*/0.014096,-0.022658,/*Bracketed WZ:*/0.055991,0.004413)
);
const vec4 Kernel1BracketsRealXY_ImZW = vec4(0.000115,0.559524,0.000000,0.178226);
const vec2 Kernel1Weights_RealX_ImY = vec2(0.513282,4.561110);
const vec4 Kernel1_RealX_ImY_RealZ_ImW[] = vec4[](
        vec4(/*XY: Non Bracketed*/0.000115,0.009116,/*Bracketed WZ:*/0.000000,0.051147),
        vec4(/*XY: Non Bracketed*/0.005324,0.013416,/*Bracketed WZ:*/0.009311,0.075276),
        vec4(/*XY: Non Bracketed*/0.013753,0.016519,/*Bracketed WZ:*/0.024376,0.092685),
        vec4(/*XY: Non Bracketed*/0.024700,0.017215,/*Bracketed WZ:*/0.043940,0.096591),
        vec4(/*XY: Non Bracketed*/0.036693,0.015064,/*Bracketed WZ:*/0.065375,0.084521),
        vec4(/*XY: Non Bracketed*/0.047976,0.010684,/*Bracketed WZ:*/0.085539,0.059948),
        vec4(/*XY: Non Bracketed*/0.057015,0.005570,/*Bracketed WZ:*/0.101695,0.031254),
        vec4(/*XY: Non Bracketed*/0.062782,0.001529,/*Bracketed WZ:*/0.112002,0.008578),
        vec4(/*XY: Non Bracketed*/0.064754,0.000000,/*Bracketed WZ:*/0.115526,0.000000),
        vec4(/*XY: Non Bracketed*/0.062782,0.001529,/*Bracketed WZ:*/0.112002,0.008578),
        vec4(/*XY: Non Bracketed*/0.057015,0.005570,/*Bracketed WZ:*/0.101695,0.031254),
        vec4(/*XY: Non Bracketed*/0.047976,0.010684,/*Bracketed WZ:*/0.085539,0.059948),
        vec4(/*XY: Non Bracketed*/0.036693,0.015064,/*Bracketed WZ:*/0.065375,0.084521),
        vec4(/*XY: Non Bracketed*/0.024700,0.017215,/*Bracketed WZ:*/0.043940,0.096591),
        vec4(/*XY: Non Bracketed*/0.013753,0.016519,/*Bracketed WZ:*/0.024376,0.092685),
        vec4(/*XY: Non Bracketed*/0.005324,0.013416,/*Bracketed WZ:*/0.009311,0.075276),
        vec4(/*XY: Non Bracketed*/0.000115,0.009116,/*Bracketed WZ:*/0.000000,0.051147)
);

vec2 multComplex(vec2 p, vec2 q)
{
    return vec2(p.x*q.x-p.y*q.y, p.x*q.y+p.y*q.x);
}

vec4 getFilters(int x)
{
  vec2 c0 = Kernel0_RealX_ImY_RealZ_ImW[x].xy;
  vec2 c1 = Kernel1_RealX_ImY_RealZ_ImW[x].xy;
  return vec4(c0.x, c0.y, c1.x, c1.y);
}

float LinearizeDepth(vec2 uv){   
  float depthNDC = texture2D(blurTex0, uv).r;
  #if DEPTH_CLIP01
    depthNDC = 2.0 * depthNDC - 1.0;
  #endif

    float n22 = viewProjection[2][2];

    return abs(((1.0 + depthNDC) * (1.0 + n22))/(2.0 * (depthNDC + n22)));
}

vec2 GetFilterCoords(int i, vec2 uv, vec2 stepVal, float filterRadius, inout int compI)
{
  float filterDistance = float(i)*filterRadius;
  vec2 coords = uv + stepVal*filterDistance;
  float targetFilterRadius = texture2D(origTex, coords).a;
  // if (targetFilterRadius < max(filterDistance, 1.2) / float(KERNEL_RADIUS))
  if (targetFilterRadius - filterRadius < -0.02 / float(KERNEL_RADIUS))
  // if (targetFilterRadius < 1.2 / float(KERNEL_RADIUS))
  {
  //   compI = -i;
  //   float correctionOffset = 0.0;
  //   correctionOffset = compI < 0 ? 0.5 : -0.5;
  //   filterDistance = (float(compI) + correctionOffset)*filterRadius;
  //   coords = uv + stepVal*filterDistance;
  //   targetFilterRadius = texture2D(origTex, coords).a;
  //   if (targetFilterRadius < max(filterDistance, 1.2)/ float(KERNEL_RADIUS))
  // // if (targetFilterRadius - filterRadius < -0.02 / float(KERNEL_RADIUS))
  //   // if (targetFilterRadius < 1.2 / float(KERNEL_RADIUS))
  //   { 
    filterDistance = (float(compI))*targetFilterRadius;
    coords = uv + stepVal*filterDistance;
      // filterDistance = filterDistance/filterRadius * targetFilterRadius;
      // compI = 0;
      // coords = uv;// + stepVal*filterDistance;
    // }
  }
  return coords;
}

void main()
{
  vec4 fragColor = vec4(0,0,0,0);
	vec2 uv = gl_TexCoord[0].st;

	if (pass == FILTER_SIZE_PASS)
	{  
    vec4 colors = texture2D(origTex, uv);

    float depth = LinearizeDepth(uv);
    float centerDepth = LinearizeDepth(vec2(0.5,0.5));
    float focusDepth = centerDepth;
    float fstopFactor = max(0.3/(max(focusDepth, 0.015)) - 2, 0);

  	fragColor = vec4(colors.rgb, clamp(abs(depth - focusDepth) * fstopFactor, 0, 0.5));
    // fragColor = vec4(depth, depth, depth, 2.0/float(KERNEL_RADIUS));
    gl_FragData[0] = fragColor;
  }

  else if (pass == VERT_BLUR_PASS)
  {
    vec2 stepVal = 1.0/resolution.xy;
    
    // vec4 val = vec4(0,0,0,0);
    vec4 valR = vec4(0,0,0,0);
    vec4 valG = vec4(0,0,0,0);
    vec4 valB = vec4(0,0,0,0);
    float filterRadius = texture2D(origTex, uv).a;
    int compI = 0;
    for (int i=-KERNEL_RADIUS; i <=KERNEL_RADIUS; ++i)
    {
      compI = i;
      vec2 coords = GetFilterCoords(i, uv, vec2(0.0, stepVal.y), filterRadius, compI);
      if (compI < -KERNEL_RADIUS) continue;

      vec4 imageTexelRGB = texture2D(origTex, coords);
      float imageTexel = 0.0;
      vec4 c0_c1 = getFilters(compI+KERNEL_RADIUS);
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

	else if (pass == HORIZ_BLUR_PASS)
	{
    vec2 stepVal = 1.0/resolution.xy;
  
    vec4 valR = vec4(0,0,0,0);
    vec4 valG = vec4(0,0,0,0);
    vec4 valB = vec4(0,0,0,0);
    float filterRadius = texture2D(origTex, uv).a;
    int compI = 0;
    for (int i=-KERNEL_RADIUS; i <=KERNEL_RADIUS; ++i)
    {
    	compI = i;
      vec2 coords = GetFilterCoords(i, uv, vec2(stepVal.x, 0.0), filterRadius, compI);
      if (compI < -KERNEL_RADIUS) continue;
      vec4 imageTexelR = texture2D(blurTex0, coords);  
      vec4 imageTexelG = texture2D(blurTex1, coords);  
      vec4 imageTexelB = texture2D(blurTex2, coords);  
      
      vec4 c0_c1 = getFilters(compI+KERNEL_RADIUS);
      
      
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
    fragColor = vec4(redChannel,greenChannel,blueChannel,filterRadius);   
    gl_FragData[0] = fragColor;
	}

	else if (pass == COMPOSITION_PASS)
	{
    float filterRadius = texture2D(blurTex0, uv).a;
		fragColor = mix(texture2D(origTex, uv), texture2D(blurTex0, uv), 
      clamp((filterRadius - 0.7 / float(KERNEL_RADIUS)) * float(KERNEL_RADIUS) * 2.0, 0.0, 1.0));
    // if (filterRadius > 2.0 / float(KERNEL_RADIUS))
      // fragColor = texture2D(blurTex0, uv);
    // else
    //   fragColor = texture2D(origTex, uv);
    gl_FragData[0] = fragColor;
	}

}
