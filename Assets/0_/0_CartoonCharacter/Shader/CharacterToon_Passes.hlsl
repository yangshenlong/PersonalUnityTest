/*
    文件定位：
        - 封装两个 Pass 的 fragment 函数，统一调用 Input 初始化与 Lighting 逻辑。
        - PrepassFragment：执行 Prepass 光照并写入 _GBufferA。
        - ToonFragment：读取 _GBufferA，执行最终合成。
    依赖：
        - CharacterToon_Common/Input。
        - CharacterToon_Lighting_Prepass/Composite。
*/
#ifndef CHARACTER_TOON_PASSES_INCLUDED
#define CHARACTER_TOON_PASSES_INCLUDED

#include "CharacterToon_Common.hlsl"
#include "CharacterToon_Input.hlsl"
#include "CharacterToon_Lighting_Prepass.hlsl"
#include "CharacterToon_Lighting_Composite.hlsl"

half4 PrepassFragment(Varyings input) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    ToonSurfaceData s = InitializeSurfaceData(input);
    ToonInputData d   = InitializeInputData(input);

    return PrepassShade(s, d);
}

half4 ToonFragment(Varyings input) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    ToonSurfaceData s = InitializeSurfaceData(input);
    clip(s.alpha - _Cutoff);

    ToonInputData d = InitializeInputData(input);
    half3 color = CompositeShading(s, d, input.uv);

    return half4(color, s.alpha);
}

#endif // CHARACTER_TOON_PASSES_INCLUDED

