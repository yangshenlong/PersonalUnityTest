Shader "DesertOasis/Env/Sand_ToonLit"
{
    Properties
    {
        [Header(Base Properties)]
        [Space(5)]
        _BaseColor("Base Color (基础颜色)", Color) = (0.95, 0.88, 0.72, 1)
        _MainTex("Main Texture (主纹理)", 2D) = "white" {}
        _Roughness("Roughness (粗糙度)", Range(0, 1)) = 0.65

        [Header(Surface Normal Maps)]
        [Space(5)]
        _NormalMapShallowX("Shallow Normal X (浅坡法线X)", 2D) = "bump" {}
        _NormalMapShallowZ("Shallow Normal Z (浅坡法线Z)", 2D) = "bump" {}
        _NormalMapSteepX  ("Steep Normal X (陡坡法线X)",  2D) = "bump" {}
        _NormalMapSteepZ  ("Steep Normal Z (陡坡法线Z)",  2D) = "bump" {}
        [Space(5)]
        _ShallowBumpScale  ("Shallow Bump Scale (浅坡凹凸强度)",  Range(0, 2)) = 0.8
        _SteepBumpScale    ("Steep Bump Scale (陡坡凹凸强度)",    Range(0, 2)) = 1.2
        _SurfaceNormalScale("Surface Normal Blend (表面法线混合)", Range(0, 5)) = 1.5

        [Header(Ocean Style Specular)]
        [Space(5)]
        _SpecDetailNormal ("Spec Detail Normal (高光细节法线)", 2D) = "bump" {}
        _SpecColor("Specular Color (高光颜色)", Color) = (1, 0.98, 0.92, 1)
        _SpecIntensity("Specular Intensity (高光强度)", Range(0, 5)) = 1.8
        [Space(5)]
        _BaseSpecRoughness("Base Spec Roughness (基础高光粗糙度)", Range(0.05, 2)) = 0.4
        _SpecRoughness ("Detail Spec Roughness (细节高光粗糙度)", Range(0.05, 2)) = 0.25

        [Header(Shadow and Lighting)]
        [Space(5)]
        _ShadowColor   ("Shadow Fill Color (阴影填充颜色)", Color) = (0.45, 0.35, 0.25, 1)
        _ShadowStrength("Shadow Fill Strength (阴影填充强度)", Range(0, 1)) = 0.4
        _AmbientMin("Ambient Min (背光面最低亮度)", Range(0, 1)) = 0.25

        [Header(Glitter Sparkle)]
        [Space(5)]
        _GlitterTex     ("Glitter Noise Map (闪光噪点贴图)", 2D) = "white" {}
        _GlitterColor   ("Glitter Color (闪光颜色)", Color) = (1, 0.95, 0.85, 1)
        _GlitterMutiplyer("Glitter Intensity (闪光强度)", Range(0, 5)) = 2.0
        [Space(5)]
        _Glitterness    ("Glitterness (闪光锐度)", Range(0.1, 10)) = 4.5
        _GlitterRange   ("Glitter Range (闪光范围)", Range(0.1, 5)) = 1.8
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
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            Cull Back
            ZWrite On
            Blend One Zero

            HLSLPROGRAM

            #pragma vertex   vert
            #pragma fragment frag

            // 多光 / 阴影变体
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile _ _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            // ========= 1. 材质参数区 =========
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float4 _MainTex_ST;
                float  _Roughness;

                float4 _NormalMapShallowX_ST;
                float4 _NormalMapShallowZ_ST;
                float4 _NormalMapSteepX_ST;
                float4 _NormalMapSteepZ_ST;

                float  _ShallowBumpScale;
                float  _SteepBumpScale;
                float  _SurfaceNormalScale;

                float4 _SpecDetailNormal_ST;

                float4 _SpecColor;
                float  _SpecIntensity;
                float  _BaseSpecRoughness;
                float  _SpecRoughness;

                float4 _ShadowColor;
                float  _ShadowStrength;

                float  _AmbientMin;

                // ★ Glitter：ST & 参数
                float4 _GlitterTex_ST;
                float  _Glitterness;
                float  _GlitterRange;
                float4 _GlitterColor;
                float  _GlitterMutiplyer;
            CBUFFER_END

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            // 法线贴图
            TEXTURE2D(_NormalMapShallowX);
            SAMPLER(sampler_NormalMapShallowX);

            TEXTURE2D(_NormalMapShallowZ);
            SAMPLER(sampler_NormalMapShallowZ);

            TEXTURE2D(_NormalMapSteepX);
            SAMPLER(sampler_NormalMapSteepX);

            TEXTURE2D(_NormalMapSteepZ);
            SAMPLER(sampler_NormalMapSteepZ);

            TEXTURE2D(_SpecDetailNormal);
            SAMPLER(sampler_SpecDetailNormal);

            // ★ Glitter 噪点贴图
            TEXTURE2D(_GlitterTex);
            SAMPLER(sampler_GlitterTex);

            // ==================== 函数区 ====================

            half OrenNayarDiffuse(float3 lightDir, float3 viewDir, float3 norm, half roughness)
            {
                lightDir = normalize(lightDir);
                viewDir  = normalize(viewDir);
                norm     = normalize(norm);

                half VdotN = saturate(dot(viewDir, norm));

                half LdotN = dot(lightDir, norm * float3(1, 0.3, 1));
                LdotN      = saturate(LdotN * 4.0);

                half cos_theta_i = LdotN;
                half theta_r     = acos(VdotN);
                half theta_i     = acos(cos_theta_i);

                float3 v_perp = viewDir  - norm * VdotN;
                float3 l_perp = lightDir - norm * LdotN;
                half   cos_phi_diff = dot(normalize(v_perp), normalize(l_perp));

                half alpha  = max(theta_r, theta_i);
                half beta   = min(theta_r, theta_i);
                half sigma2 = roughness * roughness;
                half A      = 1.0 - 0.5 * sigma2 / (sigma2 + 0.33);
                half B      = 0.45 * sigma2 / (sigma2 + 0.09);

                return saturate(cos_theta_i) *
                       (A + (B * saturate(cos_phi_diff) * sin(alpha) * tan(beta)));
            }

            // 根据世界法线方向 + 坡度，从 4 张 normal map 混合出切线空间法线
            float3 GetSurfaceNormal(float2 uv, float3 temNormalsWS)
            {
                float3 n = normalize(temNormalsWS);

                // ---1 XZ 方向权重，决定用 X 方向纹理还是 Z 方向纹理
                float xzRate = atan(abs(n.z / max(abs(n.x), 1e-4)));
                xzRate = saturate(pow(xzRate, 9.0));

                // ---2 坡度：y 越小越陡峭
                float invY = 1.0 / max(abs(n.y), 1e-3);
                float steepness = atan(invY);
                steepness = saturate(pow(steepness, 2.0));

                // --- 3 采样浅坡 normal（X/Z）
                float2 uvShallowX = TRANSFORM_TEX(uv, _NormalMapShallowX);
                float2 uvShallowZ = TRANSFORM_TEX(uv, _NormalMapShallowZ);

                float3 shallowX = SAMPLE_TEXTURE2D(_NormalMapShallowX, sampler_NormalMapShallowX, uvShallowX).rgb * 2.0 - 1.0;
                float3 shallowZ = SAMPLE_TEXTURE2D(_NormalMapShallowZ, sampler_NormalMapShallowZ, uvShallowZ).rgb * 2.0 - 1.0;
                float3 shallow  = normalize(shallowX * shallowZ) * _ShallowBumpScale;

                // --- 4 采样陡坡 normal（X/Z）
                float2 uvSteepX = TRANSFORM_TEX(uv, _NormalMapSteepX);
                float2 uvSteepZ = TRANSFORM_TEX(uv, _NormalMapSteepZ);

                float3 steepX = SAMPLE_TEXTURE2D(_NormalMapSteepX, sampler_NormalMapSteepX, uvSteepX).rgb * 2.0 - 1.0;
                float3 steepZ = SAMPLE_TEXTURE2D(_NormalMapSteepZ, sampler_NormalMapSteepZ, uvSteepZ).rgb * 2.0 - 1.0;
                float3 steep  = normalize(steepX * steepZ) * _SteepBumpScale;

                // --- 5 按坡度插值浅坡/陡坡
                float3 nTS = normalize(lerp(shallow, steep, steepness));

                return nTS; // 切线空间法线
            }

            // ★ Ocean 风格高光
            half OceanSpecular(
                half  specRoughness,
                half  baseSpecRoughness,
                float3 lightDir,
                float3 viewDir,
                float3 normalWS,
                float3 normalDetailWS
            )
            {
                lightDir       = normalize(lightDir);
                viewDir        = normalize(viewDir);
                normalWS       = normalize(normalWS);
                normalDetailWS = normalize(normalDetailWS);

                float3 h = normalize(lightDir + viewDir);

                half nh_base   = saturate(dot(h, normalWS));
                half nh_detail = saturate(dot(h, normalDetailWS));

                half baseR = max(baseSpecRoughness, 0.01);
                half r     = max(specRoughness,     0.01);

                half baseShine = pow(nh_base,   10.0 / baseR);
                half shine     = pow(nh_detail, 10.0 / r);

                return baseShine * shine;
            }

            // ★ Glitter：噪点采样
            float3 GetGlitterNoise(float2 uv)
            {
                float2 uvG = TRANSFORM_TEX(uv, _GlitterTex);
                return SAMPLE_TEXTURE2D(_GlitterTex, sampler_GlitterTex, uvG).rgb;
            }

            // ★ Glitter：分布函数（基本按照你当年的逻辑）
            float GlitterDistribution(float3 normalWS, float3 viewDir, float2 uv)
            {
                normalWS = normalize(normalWS);
                viewDir  = normalize(viewDir);

                // 视角相关分布：N·V 越接近 -1（掠射角），specBase 越大
                // ★ 降低系数从 2.0 到 1.5，扩大视角范围
                float specBase = saturate(1.0 - dot(normalWS, viewDir) * 1.5);
                float specPow  = pow(specBase, 10.0 / max(_GlitterRange, 0.001));

                // 两次噪点采样（静态，不随时间流动）
                float2 uv1 = uv + float2(0.0, viewDir.x * 0.006);
                float2 uv2 = uv + float2(0.0, viewDir.y * 0.004);

                float p1 = GetGlitterNoise(uv1).r;
                float p2 = GetGlitterNoise(uv2).g;

                float sum = 4.0 * p1 * p2;

                // 离散化噪点
                float glitter = pow(sum, _Glitterness);
                // ★ 降低阈值从 0.5 到 0.3，让更多噪点通过，增加显示范围
                glitter = max(0.0, glitter * _GlitterMutiplyer - 0.3) * 2.0;

                float sparkle = saturate(glitter * specPow);
                return sparkle;
            }

            // ==================== 顶点 / 片元 ====================

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float2 uv         : TEXCOORD0;
                float4 tangentOS  : TANGENT;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS   : TEXCOORD1;
                float2 uv         : TEXCOORD2;

                float3 viewDirWS  : TEXCOORD3;
                float3 tangentWS  : TEXCOORD4;
                float3 bitangentWS: TEXCOORD5;
            };

            Varyings vert (Attributes IN)
            {
                Varyings OUT;

                float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                float3 normalWS   = TransformObjectToWorldNormal(IN.normalOS);

                OUT.positionWS = positionWS;
                OUT.normalWS   = normalWS;
                OUT.uv         = IN.uv;

                OUT.viewDirWS  = GetWorldSpaceViewDir(positionWS);

                float3 tangentWS = TransformObjectToWorldDir(IN.tangentOS.xyz);
                tangentWS = normalize(tangentWS);
                float sign = IN.tangentOS.w;
                float3 bitangentWS = normalize(cross(normalWS, tangentWS) * sign);
                OUT.tangentWS   = tangentWS;
                OUT.bitangentWS = bitangentWS;

                OUT.positionCS = TransformWorldToHClip(positionWS);

                return OUT;
            }

            half4 frag (Varyings IN) : SV_Target
            {
                float3 baseNormalWS = normalize(IN.normalWS);
                float3 viewDir      = normalize(IN.viewDirWS);

                // 表面法线（来自 4 张 normal map）
                float3 normalTS    = GetSurfaceNormal(IN.uv, baseNormalWS);
                float3 T           = normalize(IN.tangentWS);
                float3 B           = normalize(IN.bitangentWS);
                float3 N           = baseNormalWS;
                float3x3 TBN       = float3x3(T, B, N);
                float3 normalMapWS = normalize(mul(TBN, normalTS));

                float3 finalNormalWS = normalize(normalMapWS * _SurfaceNormalScale + baseNormalWS);

                // Spec 细节 normal（高频小波纹）
                float2 uvSpec       = TRANSFORM_TEX(IN.uv, _SpecDetailNormal);
                float3 specTS       = SAMPLE_TEXTURE2D(_SpecDetailNormal, sampler_SpecDetailNormal, uvSpec).rgb * 2.0 - 1.0;
                float3 specNormalWS = normalize(mul(TBN, specTS));

                // 主光：把阴影强度单独拿出来
                Light mainLight   = GetMainLight(TransformWorldToShadowCoord(IN.positionWS));
                float shadowAtten = mainLight.shadowAttenuation;
                float3 mainDir    = normalize(mainLight.direction);
                float3 mainColLit = mainLight.color * mainLight.distanceAttenuation * shadowAtten;
                float3 mainColNoSh= mainLight.color * mainLight.distanceAttenuation;

                // 主纹理
                float2 uv      = TRANSFORM_TEX(IN.uv, _MainTex);
                float4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);

                // 环境光
                float3 ambientCol = SampleSH(finalNormalWS);

                // 主光漫反射
                half mainDiffTerm = OrenNayarDiffuse(mainDir, viewDir, finalNormalWS, _Roughness);
                // 提高背光下限
                mainDiffTerm = mainDiffTerm * (1.0 - _AmbientMin) + _AmbientMin;

                float3 diffuseCol = mainTex.rgb * _BaseColor.rgb * mainColLit * mainDiffTerm;

                // 主光 Ocean spec
                half   mainSpecTerm = OceanSpecular(_SpecRoughness, _BaseSpecRoughness, mainDir, viewDir, finalNormalWS, specNormalWS);
                float3 specColSum   = _SpecColor.rgb * mainSpecTerm * mainColLit * _SpecIntensity;

                // 额外光
                uint additionalCount = GetAdditionalLightsCount();
                for (uint i = 0u; i < additionalCount; i++)
                {
                    Light addLight = GetAdditionalLight(i, IN.positionWS);
                    float3 addDir  = normalize(addLight.direction);
                    float3 addCol  = addLight.color * addLight.distanceAttenuation * addLight.shadowAttenuation;

                    half addDiffTerm = OrenNayarDiffuse(addDir, viewDir, finalNormalWS, _Roughness);
                    float3 addDiffuseCol = mainTex.rgb * _BaseColor.rgb * addCol * addDiffTerm;
                    diffuseCol += addDiffuseCol;

                    half addSpecTerm = OceanSpecular(_SpecRoughness, _BaseSpecRoughness, addDir, viewDir, finalNormalWS, specNormalWS);
                    float3 addSpecCol = _SpecColor.rgb * addSpecTerm * addCol * _SpecIntensity;
                    specColSum += addSpecCol;
                }

                // 阴影染色
                float shadowFactor = saturate(1.0 - shadowAtten);
                float3 shadowFill  = _ShadowColor.rgb * shadowFactor * _ShadowStrength;
                shadowFill *= lerp(float3(1, 1, 1), mainTex.rgb * _BaseColor.rgb, 0.3);

                // ★ Glitter 颜色（不乘光颜色，保持“自己发光”的感觉）
                float glitterTerm = GlitterDistribution(finalNormalWS, viewDir, IN.uv);
                float3 glitterCol = _GlitterColor.rgb * glitterTerm;

                // 最终颜色
                float3 finalCol = diffuseCol
                                + specColSum
                                + ambientCol * mainTex.rgb
                                + shadowFill
                                + glitterCol;

                return half4(finalCol, _BaseColor.a);
            }

            ENDHLSL
        }
    }

    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
