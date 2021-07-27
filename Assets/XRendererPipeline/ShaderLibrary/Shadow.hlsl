#ifndef X_SHADOW_INCLUDED
#define X_SHADOW_INCLUDED

#include "./LightInput.hlsl"
#include "./ShadowInput.hlsl"
#include "./SpaceTransform.hlsl"
#include "./ShadowTentFilter.hlsl"
#include "./ShadowBias.hlsl"


#define ACTIVED_CASCADE_COUNT _ShadowParams.w

int GetCascadeIndex(float3 positionWS)
{
    for (int i = 0; i < ACTIVED_CASCADE_COUNT; i++)
    {
        float4 cullingSphere = _XCascadeCullingSpheres[i];
        float3 center = cullingSphere.xyz;
        float radiusSqr = cullingSphere.w * cullingSphere.w;
        float3 d = (positionWS - center);
        //计算世界坐标是否在包围球内。
        if (dot(d, d) <= radiusSqr)
        {
            return i;
        }
    }
    return - 1;
}


///将世界坐标转换到ShadowMapTexture空间,返回值的xy为uv，z为深度
float3 WorldToShadowMapPos(float3 positionWS, int cascadeIndex)
{
    if (cascadeIndex >= 0)
    {
        float4x4 worldToCascadeMatrix = _XWorldToMainLightCascadeShadowMapSpaceMatrices;
        float4 shadowMapPos = mul(worldToCascadeMatrix, float4(positionWS, 1));
        // return shadowMapPos.www;
        shadowMapPos /= shadowMapPos.w;
        // shadowMapPos.xyz = shadowMapPos.xyz * 0.5 + 0.5;
        return shadowMapPos;
    }
    else
    {
        // return 0;
        //表示超出ShadowMap. 不显示阴影。
#if UNITY_REVERSED_Z
        return float3(0, 0, 1);
#else
        return float3(0, 0, 1);
#endif
    }
}

float3 WorldToShadowMapPos(float3 positionWS)
{
    // int cascadeIndex = GetCascadeIndex(positionWS);
    return WorldToShadowMapPos(positionWS, 0);
}



///采样阴影强度，返回区间[0,1]
float SampleShadowStrength(float3 uvd)
{
#if X_SHADOW_PCF
    float atten = 0;
    if (_ShadowAAParams.x == 1)
    {
        atten = SampleShadowPCF(uvd);
    }
    else if (_ShadowAAParams.x == 2)
    {
        atten = SampleShadowPCF3x3_4Tap_Fast(uvd);
    }
    else if (_ShadowAAParams.x == 3)
    {
        atten = SampleShadowPCF3x3_4Tap(uvd);
    }
    else if (_ShadowAAParams.x == 4)
    {
        atten = SampleShadowPCF5x5_9Tap(uvd);
    }
    else
    {
        atten = SampleShadowPCF(uvd);
    }
    // return atten;
    return 1 - atten;
#else
    // return 1;
    float depth = _XMainShadowMap.Sample(sampler_XMainShadowMap_point_clamp, uvd.xy);
    // return depth;
    // float depth = UNITY_SAMPLE_TEX2D(_XMainShadowMap,uvd.xy);
    //    return step(uvd.z,depth);
#if UNITY_REVERSED_Z
    //depth > z
    return step(uvd.z, depth);
#else
    return step(depth, uvd.z);
#endif

#endif
}

///检查世界坐标是否位于主灯光的阴影之中(1表示不在阴影中，小于1表示在阴影中,数值代表了阴影衰减)
float3 GetMainLightShadowAtten(float3 positionWS, float3 normalWS)
{

    // return  _ShadowParams.z;
#if _RECEIVE_SHADOWS_OFF
    return 1;
#else
    if (_ShadowParams.z == 0)
    {
        return 1;
    }
    int cascadeIndex = 0;// GetCascadeIndex(positionWS);
#if X_SHADOW_BIAS_RECEIVER_PIXEL
    positionWS = ApplyShadowBias(positionWS, normalWS, _XMainLightDirection, cascadeIndex);
#endif

    float pdistance = distance(positionWS, _WorldSpaceCameraPos.xyz);
    pdistance = saturate(step(pdistance, 3));
    // return positionWS;
    float3 shadowMapPos = WorldToShadowMapPos(positionWS, cascadeIndex);
    // return shadowMapPos;
    // float4 TempdepthColor = tex2D(_XMainShadowMapMask, shadowMapPos.xy) ;
    // float Tempdepth = DecodeFloatRG(TempdepthColor.ar);
    // return Tempdepth ;
    // return GetNDC(shadowMapPos.xy, Tempdepth).xyz;


    float shadowStrength = SampleShadowStrength(shadowMapPos) * pdistance;
    // return shadowStrength;
    return 1 - shadowStrength * _ShadowParams.z;
#endif
}

#endif