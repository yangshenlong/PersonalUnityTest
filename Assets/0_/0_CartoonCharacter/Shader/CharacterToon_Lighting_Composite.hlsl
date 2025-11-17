/*
    文件定位：
        - 第二遍 Composite Pass 的光照模板。
        - 读取 _GBufferA（Prepass 输出），叠加 Shadow / Spec / Emission / Fresnel / Depth Rim / 上下渐变 / Fog 等。
    依赖：
        - CharacterToon_Common/Input：数据结构。
        - 外部绑定的 _GBufferA RenderTexture。
*/
#ifndef CHARACTER_TOON_LIGHTING_COMPOSITE_INCLUDED
#define CHARACTER_TOON_LIGHTING_COMPOSITE_INCLUDED

#include "CharacterToon_Common.hlsl"
#include "CharacterToon_Input.hlsl"

TEXTURE2D(_GBufferA);
SAMPLER(sampler_GBufferA);
// 说明：真实项目应由 Renderer/SRP 绑定 _GBufferA；模板中仅示例。

half3 ComputeShadowTerm(ToonSurfaceData s, ToonInputData d)
{
    Light mainLight = GetMainLight(d.shadowCoord);
    half shadow = mainLight.shadowAttenuation;
    return s.baseColor * (shadow - 1.0h) * 0.3h;
}

half3 ComputeSpecularTerm(ToonSurfaceData s, ToonInputData d)
{
    Light mainLight = GetMainLight(d.shadowCoord);
    half3 halfDir = SafeNormalize(-mainLight.direction + d.viewDirWS);
    half nh = saturate(dot(s.normalWS, halfDir));
    half spec = pow(nh, 16.0h) * _SpecIntensity;
    return _SpecColor.rgb * spec;
}

half3 ComputeEmissionTerm(ToonSurfaceData s)
{
    return _EmissionColor.rgb * _EmissionIntensity;
}

half3 ComputeFresnelTerm(ToonSurfaceData s, ToonInputData d)
{
    half rim = 1.0h - saturate(dot(s.normalWS, d.viewDirWS));
    rim = pow(rim, _FresnelPower) * _FresnelIntensity;
    return _FresnelColor.rgb * rim;
}

half3 ComputeDepthRimLight(ToonSurfaceData s, ToonInputData d)
{
    half depthFactor = saturate((d.positionWS.z - 1.0h) * 0.1h);
    half3 color = _FresnelColor.rgb * depthFactor * 0.3h;
    return color;
}

half3 ComputeVerticalGradient(float3 positionWS)
{
    half height = saturate((positionWS.y + 1.0h) * 0.5h);
    return lerp(_BottomColor.rgb, _TopColor.rgb, height);
}

half3 ApplyFog(half3 color, float3 positionWS)
{
    half dist = saturate(length(positionWS) * 0.02h);
    half fogFactor = saturate(dist * _FogIntensity);
    return lerp(color, _FogColor.rgb, fogFactor);
}

half3 CompositeShading(ToonSurfaceData s, ToonInputData d, float2 uv)
{
    half4 gbuffer = SAMPLE_TEXTURE2D(_GBufferA, sampler_GBufferA, uv);
    half3 preColor = gbuffer.rgb;

    half3 shadow   = ComputeShadowTerm(s, d);
    half3 spec     = ComputeSpecularTerm(s, d);
    half3 emission = ComputeEmissionTerm(s);
    half3 fresnel  = ComputeFresnelTerm(s, d);
    half3 depthRim = ComputeDepthRimLight(s, d);
    half3 gradient = ComputeVerticalGradient(d.positionWS);

    half3 finalColor = preColor + shadow + spec + emission + fresnel + depthRim + gradient;
    finalColor = ApplyFog(finalColor, d.positionWS);
    return finalColor;
}

#endif // CHARACTER_TOON_LIGHTING_COMPOSITE_INCLUDED

