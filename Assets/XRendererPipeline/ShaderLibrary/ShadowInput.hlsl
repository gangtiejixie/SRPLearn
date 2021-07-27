#ifndef X_SHADOW_INPUT_INCLUDED
#define X_SHADOW_INPUT_INCLUDED

#define MAX_CASCADESHADOW_COUNT 4

CBUFFER_START(XShadow)

//主灯光 世界空间->投影空间变换矩阵
float4x4 _XWorldToMainLightCascadeShadowMapSpaceMatrices;

float4 _XCascadeCullingSpheres[MAX_CASCADESHADOW_COUNT];

CBUFFER_END

sampler2D _XMainShadowMapMask;



#if X_SHADOW_PCF
Texture2D _XMainShadowMap;
SamplerComparisonState sampler_XMainShadowMap;
SamplerState sampler_XMainShadowMap_point_clamp;
half4 _ShadowAAParams; //x is PCF tap count, current support 1 & 4
#else
Texture2D_float _XMainShadowMap;
SamplerState sampler_XMainShadowMap_point_clamp;
#endif

float4 _ShadowParams; //x is depthBias,y is normal bias,z is strength,w is cascadeCount

float4 _ShadowMapSize; //x = 1/shadowMap.width, y = 1/shadowMap.height,z = shadowMap.width,w = shadowMap.height
inline float DecodeFloatRG(float2 enc)
{
    float2 kDecodeDot = float2(1.0, 1 / 255.0);
    return dot(enc, kDecodeDot);
}


float4 GetNDC(float2 uv, float depth)
{
    float4 ndc = float4(uv.x * 2 - 1, uv.y * 2 - 1, depth * 2 - 1, 1);
    float4 worldPos = mul(_XWorldToMainLightCascadeShadowMapSpaceMatrices, ndc);
    worldPos /= worldPos.w;
    return worldPos;
}


#endif