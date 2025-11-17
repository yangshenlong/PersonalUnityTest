/*
    文件定位：
        - Toon Shader 全局公共定义，所有 Pass 引用。
        - 包含 Surface/Input 结构与通用数学函数（SafeNormalize 等）。
        - 未来扩展（如头发高光、眼睛特效）也基于此结构共享数据。
    依赖：无；被 CharacterToon_Input、Lighting、Passes 等引用。
*/
#ifndef CHARACTER_TOON_COMMON_INCLUDED
#define CHARACTER_TOON_COMMON_INCLUDED

struct ToonSurfaceData
{
    half3 baseColor;
    half  alpha;
    half3 normalWS;
    half  smoothness;
    half  metallic;
    half  occlusion;
};

struct ToonInputData
{
    float3 positionWS;
    half3  normalWS;
    half3  viewDirWS;
    float4 shadowCoord;
    half2  lightmapUV;
};

inline half3 SafeNormalize(half3 v)
{
    return normalize(v + half3(1e-5h, 1e-5h, 1e-5h));
}

#endif // CHARACTER_TOON_COMMON_INCLUDED

