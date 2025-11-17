/*
    文件定位说明：
        - 本文档位于 `Assets/0_/0_CartoonCharacter/Shader/`，用于总结该目录中各 Shader/HLSL 文件在 Toon 角色渲染流程中的职责。
        - 所有描述基于当前模板，方便团队成员快速了解每个文件的作用与互相依赖关系。
*/

# Character Toon Shader 模板文件说明

## CharacterToon.shader
- 角色 Toon Shader 主入口，定义材质属性与两个Pass。
- Pass `Prepass`（LightMode=`CharacterPrepass`）负责 Ramp Diffuse 与 Rim Shadow Light，并写入 `_GBufferA`。
- Pass `Composite`（LightMode=`UniversalForward`）采样 `_GBufferA`，叠加 Shadow、Specular、Emission、Fresnel、Depth Rim Light、上下渐变与 Fog，输出最终颜色。
- Include 了后续所有 HLSL 头文件，确保结构、输入、光照与片元函数共享。

## CharacterToon_Common.hlsl
- 公共结构与工具函数定义。
- `ToonSurfaceData` 描述材质属性（颜色、法线、金属度等）。
- `ToonInputData` 记录世界空间位置、法线、视线、阴影坐标等。
- 含 `SafeNormalize` 等基础工具，供所有 Pass 使用。

## CharacterToon_Input.hlsl
- 定义材质参数 CBUFFER，保证 SRP Batcher 兼容。
- 提供 `Attributes`、`Varyings` 结构以及 `PrepassVertex`/`ToonVertex`。
- 内联函数 `InitializeSurfaceData`、`InitializeInputData` 将 Varyings 转成通用数据，供两个 Pass 的 fragment 调用。

## CharacterToon_Lighting_Prepass.hlsl
- 第一遍光照逻辑（Prepass）。
- `ComputeRampDiffuse`：基于主光 dot(N,L) 及 Toon 阈值计算阶梯漫反射。
- `ComputeRimShadowLight`：通过视线与法线关系生成轮廓暗边。
- `PrepassShade`：组合上述项并输出 `half4(color, alpha)`，写入 `_GBufferA`。

## CharacterToon_Lighting_Composite.hlsl
- 第二遍合成光照逻辑。
- 声明 `_GBufferA` 纹理与采样器，用于读取第一遍结果。
- 包含 `ComputeShadowTerm`、`ComputeSpecularTerm`、`ComputeEmissionTerm`、`ComputeFresnelTerm`、`ComputeDepthRimLight`、`ComputeVerticalGradient`、`ApplyFog` 等函数。
- `CompositeShading` 负责整合所有特效并返回最终颜色。

## CharacterToon_Passes.hlsl
- 汇总两个 Pass 的 fragment 函数。
- `PrepassFragment`：初始化数据后调用 `PrepassShade`，写入 GBufferA。
- `ToonFragment`：裁剪透明度、初始化数据，调用 `CompositeShading` 输出最终颜色。
- 是 ShaderLab Pass 与 HLSL 逻辑之间的桥梁。

---
将本目录视为角色 Toon Shader 的最小模板，后续可在此基础上扩展更多细分材质、额外 Pass 或特效模块。若需接入实际延迟-前向混合渲染流程，需在 Renderer Feature/脚本中实现 `_GBufferA` 的 RenderTexture 绑定与 Pass 调度。

