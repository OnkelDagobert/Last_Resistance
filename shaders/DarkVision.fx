struct VS_INPUT
{
   float3 ssPosition   : POSITION;
   float2 texCoord     : TEXCOORD0;
   float4 color        : COLOR0;
};

struct VS_OUTPUT
{
   float4 ssPosition    : POSITION;
   float2 texCoord     : TEXCOORD0;
   float4 color        : COLOR0;
};

struct PS_INPUT
{
   float2 texCoord     : TEXCOORD0;
   float4 color        : COLOR0;
};

texture     baseTexture;
texture     depthTexture;
float       time;
float       startTime;
float       amount;

sampler baseTextureSampler = sampler_state
   {
       texture       = (baseTexture);
       AddressU      = Wrap;
       AddressV      = Wrap;
       MinFilter     = Linear;
       MagFilter     = Linear;
       MipFilter     = Linear;
       SRGBTexture   = False;
   };
   
sampler depthTextureSampler = sampler_state
   {
       texture       = (depthTexture);
       AddressU      = Clamp;
       AddressV      = Clamp;
       MinFilter     = Linear;
       MagFilter     = Linear;
       MipFilter     = None;
       SRGBTexture   = False;
   };   

/**
* Vertex shader.
*/  
VS_OUTPUT SFXBasicVS(VS_INPUT input)
{

   VS_OUTPUT output;

   output.ssPosition = float4(input.ssPosition, 1);
   output.texCoord   = input.texCoord;
   output.color      = input.color;

   return output;

}

float4 SFXDarkVisionPS(PS_INPUT input) : COLOR0
{

    float2 texCoord = input.texCoord;

    float2 depth1    = tex2D(depthTextureSampler, input.texCoord).rg;
    float4 inputPixel = tex2D(baseTextureSampler, input.texCoord);

//ISSUE 19:
    const float offset = 0.001 + depth1.g * 0.000001;
	float  depth2 = tex2D(depthTextureSampler, input.texCoord + float2(-offset, -offset)).r;
	float  depth3 = tex2D(depthTextureSampler, input.texCoord + float2(-offset, offset)).r;
	float  depth4 = tex2D(depthTextureSampler, input.texCoord + float2(offset,  -offset)).r;
	float  depth5 = tex2D(depthTextureSampler, input.texCoord + float2(offset, offset)).r;
	
    float4 edgeColor; 
   
    if (depth1.g > 0.5) // entities
    {
        float edge = (abs(depth2 - depth1.r) +
                abs(depth3 - depth1.r) +
                abs(depth4 - depth1.r) +
                abs(depth5 - depth1.r ));
                
        if (depth1.r < 0.2) // view model
        {
            edgeColor = float4(1, 0.5, 0, 0);
            return lerp(inputPixel, lerp(inputPixel, (edgeColor * edge), 0.5), 1);
        }
        
        // world entitites
        //ISSUE 19:

        float4 edgeColor = float4(0.42, 0.75, 1.8, 0.46) * 0.01;
        float4 fog = float4(0, 0, 0, 0) * 8.0;
		float fogDensity = 0.0001;
		float fogAmount = 1 - saturate(exp(-depth1.r * fogDensity));
        return lerp(inputPixel, lerp(inputPixel, (edgeColor * edge) + (fog * fogAmount), 0.6 + edge), 1);
    }
    else // world geometry
    {
        float edge = abs(depth5 - depth1.r );
        return lerp(inputPixel, edge, 0.01);
    }
}

technique SFXDarkVision
{
   pass p0
   {
       ZEnable             = False;
       ZWriteEnable        = False;   
       VertexShader        = compile vs_2_0 SFXBasicVS();
       PixelShader         = compile ps_2_0 SFXDarkVisionPS();
       CullMode            = None;
   }
}
