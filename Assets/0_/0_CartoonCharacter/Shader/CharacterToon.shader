/*
    文件定位：
        - 这是二次元角色主 Shader，运行在 URP 前向路径中，角色材质都指向它。
        - 依赖公共头：CharacterToon_Common/Input/Lighting_Prepass/Lighting_Composite/Passes。
    Pass 顺序与职责：
        - Pass 0 "Prepass"（LightMode=CharacterPrepass）
            · 仅计算 Ramp Diffuse 与 Rim Shadow Light，结果写入当前颜色缓冲，作为中间缓冲 _GBufferA。
            · 将光照粗略分层，便于第二遍叠加更多特效，避免重复昂贵计算。
        - Pass 1 "Composite"（LightMode=UniversalForward）
            · 采样 _GBufferA，叠加 Shadow、Specular、Emission、Fresnel、Depth Rim Light、上下渐变颜色与 Fog。
            · 输出最终屏幕颜色。
    _GBufferA 说明：
        - 模板内由第二遍直接采样 `_GBufferA` 纹理；实际项目需由 Renderer 或脚本把 Prepass 输出绑定到 RenderTexture 并传入。
    Include：
        - Core.hlsl / Lighting.hlsl：URP 基础与主光源采样。
        - CharacterToon_Common/Input：结构体、材质输入。
        - CharacterToon_Lighting_Prepass/Composite：两遍光照计算。
        - CharacterToon_Passes：统一的 fragment 流程。
*/
Shader "MyGame/CharacterToon"
{
    Properties
    {
        _BaseMap ("Base Map", 2D) = "white" {}
        _BaseColor ("Base Color", Color) = (1,1,1,1)
        _Cutoff ("Alpha Cutoff", Range(0,1)) = 0.5

        _RampThreshold ("Ramp Threshold", Range(-1,1)) = 0.2
        _RampSmooth ("Ramp Smooth", Range(0,1)) = 0.1

        _RimShadowColor ("Rim Shadow Color", Color) = (0,0,0,1)
        _RimShadowIntensity ("Rim Shadow Intensity", Range(0,1)) = 0.5

        _SpecColor ("Specular Color", Color) = (1,1,1,1)
        _SpecIntensity ("Specular Intensity", Range(0,5)) = 1

        _EmissionColor ("Emission Color", Color) = (0,0,0,1)
        _EmissionIntensity ("Emission Intensity", Range(0,5)) = 0

        _FresnelColor ("Fresnel Color", Color) = (1,1,1,1)
        _FresnelPower ("Fresnel Power", Range(0.1,8)) = 2
        _FresnelIntensity ("Fresnel Intensity", Range(0,5)) = 1

        _TopColor ("Top Gradient Color", Color) = (1,1,1,1)
        _BottomColor ("Bottom Gradient Color", Color) = (0,0,0,1)

        _FogColor ("Fog Color", Color) = (0.8,0.9,1,1)
        _FogIntensity ("Fog Intensity", Range(0,1)) = 0.2
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline"       = "UniversalRenderPipeline"
            "RenderType"           = "Opaque"
            "UniversalMaterialType"= "Lit"
            "Queue"                = "Geometry"
        }

        Pass
        {
            Name "Prepass"
            Tags { "LightMode" = "CharacterPrepass" }
            Blend One Zero
            ZWrite On
            Cull Back

            HLSLPROGRAM
            #pragma vertex   PrepassVertex
            #pragma fragment PrepassFragment
            #pragma target   4.5
            #pragma multi_compile_instancing
            #pragma multi_compile_fog

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "CharacterToon_Common.hlsl"
            #include "CharacterToon_Input.hlsl"
            #include "CharacterToon_Lighting_Prepass.hlsl"
            #include "CharacterToon_Passes.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "Composite"
            Tags { "LightMode" = "UniversalForward" }
            Blend One Zero
            ZWrite On
            Cull Back

            HLSLPROGRAM
            #pragma vertex   ToonVertex
            #pragma fragment ToonFragment
            #pragma target   4.5
            #pragma multi_compile_instancing
            #pragma multi_compile_fog

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "CharacterToon_Common.hlsl"
            #include "CharacterToon_Input.hlsl"
            #include "CharacterToon_Lighting_Prepass.hlsl"
            #include "CharacterToon_Lighting_Composite.hlsl"
            #include "CharacterToon_Passes.hlsl"
            ENDHLSL
        }
    }

    FallBack Off
}

