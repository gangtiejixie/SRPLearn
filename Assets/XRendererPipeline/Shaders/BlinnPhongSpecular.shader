﻿Shader "SRPLearn/BlinnPhongSpecular"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" { }
        _Shininess ("Shininess", Range(10, 128)) = 50
        _SpecularColor ("SpecularColor", Color) = (1, 1, 1, 1)
        _Color ("Color", Color) = (1, 1, 1, 1)
        _ShadowColor ("ShadowColor", Color) = (0, 0, 0, 1)
        
        _ShadowMask ("_ShadowMask", Range(0, 1)) = 1
        // [Toggle(_TEST_OFF)] _TEST_OFF ("TEST", Float) = 0
        
        [Toggle(_RECEIVE_SHADOWS_OFF)] _RECEIVE_SHADOWS_OFF ("Receive Shadows Off?", Float) = 0
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "LightMode" = "XForwardBase" }
        LOD 100

        HLSLINCLUDE
        #pragma enable_cbuffer
        #include "./BlinnPhongFrag.hlsl"


        ENDHLSL

        Pass
        {
            Name "DEFAULT"

            Cull Back

            HLSLPROGRAM

            #pragma multi_compile _ X_SHADOW_BIAS_RECEIVER_PIXEL
            #pragma multi_compile _ X_SHADOW_PCF
            
            #pragma vertex PassVertex
            #pragma fragment PassFragment

            #pragma shader_feature _RECEIVE_SHADOWS_OFF
            
            ENDHLSL

        }

        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            ZWrite On
            ZTest LEqual
            // ColorMask 0
            Cull Back

            HLSLPROGRAM

            #pragma multi_compile _ X_SHADOW_BIAS_CASTER_VERTEX

            #pragma shader_feature _TEST_OFF

            #include "../ShaderLibrary/ShadowCaster.hlsl"

            #pragma vertex ShadowCasterVertex
            #pragma fragment ShadowCasterFragment
            
            ENDHLSL

        }

        Pass
        {
            Name "ShadowDebug"
            Tags { "LightMode" = "ShadowDebug" }

            ZWrite Off
            ZTest LEqual
            Cull Back
            Blend SrcAlpha OneMinusSrcAlpha


            HLSLPROGRAM

            #include "../ShaderLibrary/ShadowDebug.hlsl"

            #pragma vertex ShadowDebugVertex
            #pragma fragment ShadowDebugFragment
            
            ENDHLSL

        }
    }
}
