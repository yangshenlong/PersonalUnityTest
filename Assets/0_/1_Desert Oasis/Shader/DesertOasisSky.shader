Shader "DesertOasis/Sky/Gradient"
{
    Properties
    {
        _HorizonColor   ("Horizon Color", Color) = (1, 0.85, 0.65, 1)
        _ZenithColor    ("Zenith Color",  Color) = (0.25, 0.55, 0.95, 1)
        _GradientHeight ("Gradient Height", Float) = 50.0
    }

    SubShader
    {
        Tags
        {
            "RenderType"     = "Opaque"
            "Queue"          = "Background"
            "RenderPipeline" = "UniversalPipeline"   // ← 关键改这里
        }

        Pass
        {
            Name "SkyUnlit"
            Tags { "LightMode" = "SRPDefaultUnlit" }

            // 相机在球体内部看天空：剔除正面，只画内壁
            Cull Front
            ZWrite Off
            Blend One Zero

            HLSLPROGRAM

            #pragma vertex   vert
            #pragma fragment frag
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _HorizonColor;
                float4 _ZenithColor;
                float  _GradientHeight;
            CBUFFER_END

            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);

                float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.positionWS = positionWS;
                OUT.positionCS = TransformWorldToHClip(positionWS);
                UNITY_TRANSFER_INSTANCE_ID(IN, OUT);

                return OUT;
            }

            half4 frag (Varyings IN) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN);

                float height = max(_GradientHeight, 0.0001);
                float t = saturate(IN.positionWS.y / height);

                float4 col = lerp(_HorizonColor, _ZenithColor, t);
                return col;
            }

            ENDHLSL
        }
    }

    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
