/*
    文件定位：
        - 负责定义顶点 Attributes/Varyings，并将其转换成 ToonSurfaceData / ToonInputData。
        - 被 Prepass 与 Composite 两个 Pass 共享，保证数据一致。
    依赖：
        - CharacterToon_Common：结构体、工具函数。
*/
#ifndef CHARACTER_TOON_INPUT_INCLUDED
#define CHARACTER_TOON_INPUT_INCLUDED

#include "CharacterToon_Common.hlsl"

CBUFFER_START(UnityPerMaterial)
    float4 _BaseColor;
    float   _Cutoff;
    float   _RampThreshold;
    float   _RampSmooth;
    float4 _RimShadowColor;
    float   _RimShadowIntensity;
    float4 _SpecColor;
    float   _SpecIntensity;
    float4 _EmissionColor;
    float   _EmissionIntensity;
    float4 _FresnelColor;
    float   _FresnelPower;
    float   _FresnelIntensity;
    float4 _TopColor;
    float4 _BottomColor;
    float4 _FogColor;
    float   _FogIntensity;
CBUFFER_END

TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);

struct Attributes
{
    float4 positionOS : POSITION;
    float3 normalOS   : NORMAL;
    float4 tangentOS  : TANGENT;
    float2 uv         : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS : SV_Position;
    float3 positionWS : TEXCOORD0;
    half3  normalWS   : TEXCOORD1;
    half3  viewDirWS  : TEXCOORD2;
    float2 uv         : TEXCOORD3;
    float4 shadowCoord: TEXCOORD4;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

inline Varyings ToonVertexInternal(Attributes input)
{
    Varyings output;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
    float3 normalWS   = TransformObjectToWorldNormal(input.normalOS);
    float3 viewDirWS  = GetWorldSpaceViewDir(positionWS);

    output.positionWS  = positionWS;
    output.normalWS    = SafeNormalize(normalWS);
    output.viewDirWS   = SafeNormalize(viewDirWS);
    output.positionCS  = TransformWorldToHClip(positionWS);
    output.uv          = input.uv;
    output.shadowCoord = TransformWorldToShadowCoord(positionWS);
    return output;
}

Varyings PrepassVertex(Attributes input)
{
    return ToonVertexInternal(input);
}

Varyings ToonVertex(Attributes input)
{
    return ToonVertexInternal(input);
}

inline ToonSurfaceData InitializeSurfaceData(Varyings input)
{
    ToonSurfaceData surface;
    half4 albedo = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv) * _BaseColor;
    surface.baseColor = albedo.rgb;
    surface.alpha     = albedo.a;
    surface.normalWS  = input.normalWS;
    surface.smoothness= 0.5h;
    surface.metallic  = 0.0h;
    surface.occlusion = 1.0h;
    return surface;
}

inline ToonInputData InitializeInputData(Varyings input)
{
    ToonInputData data;
    data.positionWS = input.positionWS;
    data.normalWS   = input.normalWS;
    data.viewDirWS  = input.viewDirWS;
    data.shadowCoord= input.shadowCoord;
    data.lightmapUV = half2(0, 0);
    return data;
}

#endif // CHARACTER_TOON_INPUT_INCLUDED

