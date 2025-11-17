/*
    文件定位：
        - 仅包含第一遍（Prepass）光照逻辑：Ramp Diffuse + Rim Shadow Light。
        - 输出写入当前 RenderTarget，即模板中的 _GBufferA。
    依赖：
        - CharacterToon_Common / CharacterToon_Input：提供 Surface/Input 数据。
        - URP Lighting：获取主光信息。
*/
#ifndef CHARACTER_TOON_LIGHTING_PREPASS_INCLUDED
#define CHARACTER_TOON_LIGHTING_PREPASS_INCLUDED

#include "CharacterToon_Common.hlsl"
#include "CharacterToon_Input.hlsl"

half3 ComputeRampDiffuse(ToonSurfaceData s, ToonInputData d)
{
    Light mainLight = GetMainLight(d.shadowCoord);
    half3 lightDir = SafeNormalize(mainLight.direction);
    half nl = dot(s.normalWS, -lightDir);
    half ramp = smoothstep(_RampThreshold - _RampSmooth, _RampThreshold + _RampSmooth, nl);
    return s.baseColor * mainLight.color * ramp;
}

half3 ComputeRimShadowLight(ToonSurfaceData s, ToonInputData d)
{
    half rim = 1.0h - saturate(dot(s.normalWS, d.viewDirWS));
    rim = pow(rim, 2.0h);
    half3 rimColor = _RimShadowColor.rgb * _RimShadowIntensity;
    return rimColor * rim;
}

half4 PrepassShade(ToonSurfaceData s, ToonInputData d)
{
    half3 rampDiffuse = ComputeRampDiffuse(s, d);
    half3 rimShadow   = ComputeRimShadowLight(s, d);
    half3 color       = rampDiffuse + rimShadow;
    return half4(color, s.alpha);
}

#endif // CHARACTER_TOON_LIGHTING_PREPASS_INCLUDED

