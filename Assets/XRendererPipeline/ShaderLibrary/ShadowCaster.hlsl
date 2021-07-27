#ifndef X_SHADOW_CASTER_INCLUDED
#define X_SHADOW_CASTER_INCLUDED

#include "./LightInput.hlsl"
#include "./SpaceTransform.hlsl"
#include "./ShadowBias.hlsl"

#define ACCURATE_SHADOW_BIAS 0


#if ACCURATE_SHADOW_BIAS

float3 ApplyShadowBias(float3 positionWS, float3 normalWS, float3 lightDirection)
{
    float cos = dot(normalWS, lightDirection);
    // float sin = sqrt(1 - cos * cos);
    float sin = length(cross(normalWS, lightDirection));
    float depthScale = max(0.1, sin * rcp(cos));
    float normalScale = saturate(sin * rcp(cos * cos));
    positionWS -= lightDirection * _ShadowBias.x * depthScale;
    positionWS -= normalWS * normalScale * _ShadowBias.y;
    return positionWS;
}

#endif


struct ShadowCasterAttributes
{
    float4 positionOS: POSITION;
#if X_SHADOW_BIAS_CASTER_VERTEX
    float4 normalOS: NORMAL;
#endif
};

struct ShadowCasterVaryings
{
    float4 positionCS: SV_POSITION;
    float4 Normal: TEXCOORD0;
};

ShadowCasterVaryings ShadowCasterVertex(ShadowCasterAttributes input)
{
    ShadowCasterVaryings output;
#if X_SHADOW_BIAS_CASTER_VERTEX
    float3 positionWS = TransformObjectToWorld(input.positionOS);
    float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
    positionWS = ApplyShadowCasterBias(positionWS, normalWS, _XMainLightDirection);
    output.positionCS = TransformWorldToHClip(positionWS);
    output.Normal.xyz = normalWS;
#else
    output.positionCS = UnityObjectToClipPos(input.positionOS);
#endif
    
    return output;
}

// Encoding/decoding [0..1) floats into 8 bit/channel RG. Note that 1.0 will not be encoded properly.
inline float2 EncodeFloatRG(float v)
{
    float2 kEncodeMul = float2(1.0, 255.0);
    float kEncodeBit = 1.0 / 255.0;
    float2 enc = kEncodeMul * v;
    enc = frac(enc);
    enc.x -= enc.y * kEncodeBit;
    return enc;
}

void ShadowCasterFragment(ShadowCasterVaryings input, out half4 color: SV_TARGET0)
{
    // input.positionCS.z;
// depth =  input.positionCS.z;
    // mask.ra = EncodeFloatRG(input.positionCS.z) * _ShadowMask;
//     mask.gb = EncodeFloatRG(input.positionCS.z) * _ShadowMask ;
    // mask.b = _ShadowMask;
// mask = 1;
    // mask.g = dot(input.Normal.xyz, _XMainLightDirection.xyz);
    color = 0;
    color.b = _ShadowMask;
}

#endif