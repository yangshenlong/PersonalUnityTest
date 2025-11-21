Shader "DesertOasis/Sand/Empty"
{
    Properties
    {
        _BaseColor("Base Color", Color) = (1, 1, 1, 1)
    }

    SubShader
    {
        Tags
        {
            "RenderType"     = "Opaque"
            "Queue"          = "Geometry"
            "RenderPipeline" = "UniversalPipeline"
        }

        Pass
        {
            Name "Main"
            Tags { "LightMode" = "UniversalForward" }

            Cull Back
            ZWrite On
            Blend One Zero

            HLSLPROGRAM

            #pragma vertex   vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            // ========= 1. 材质参数区（以后需要新属性就往这里加） =========
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
            CBUFFER_END

            // ========= 2. 顶点输入 / 输出结构体（以后要传的新数据就加字段） =========
            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS   : TEXCOORD1;
                float2 uv         : TEXCOORD2;
            };

            // ========= 3. 顶点着色器：目前只做最基本的变换 =========
            Varyings vert (Attributes IN)
            {
                Varyings OUT;

                float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                float3 normalWS   = TransformObjectToWorldNormal(IN.normalOS);

                OUT.positionWS = positionWS;
                OUT.normalWS   = normalWS;
                OUT.uv         = IN.uv;
                OUT.positionCS = TransformWorldToHClip(positionWS);

                return OUT;
            }

            // ========= 4. 片元着色器：现在什么都不算，只返回一个颜色 =========
            half4 frag (Varyings IN) : SV_Target
            {
                // 以后所有的 漫反射 / 高光 / 高度颜色 / 距离衰减
                // 都会从这里开始往下加，现在先保持一个纯色输出
                return _BaseColor;
            }

            ENDHLSL
        }
    }

    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
