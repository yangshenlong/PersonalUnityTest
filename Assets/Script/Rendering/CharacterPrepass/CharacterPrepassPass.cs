using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

/// <summary>
/// CharacterPrepassPass
/// - 使用 Shader 中 LightMode = "CharacterPrepass" 的 Pass，
/// - 将符合 LayerMask、RenderQueue 的物体渲染到一个 RT（_CharacterGBufferA）。
/// - 这个 RT 之后可在角色 Shader 的 Composite Pass 中采样使用。
/// </summary>
public class CharacterPrepassPass : ScriptableRenderPass
{
    static readonly ShaderTagId s_CharacterPrepassTag = new ShaderTagId("CharacterPrepass");

    CharacterPrepassFeature.CharacterPrepassSettings _settings;
    int _gbufferPropertyId;

    RenderTargetHandle _gbufferHandle;
    RTHandle _gbufferRT;

    FilteringSettings _filtering;
    string _profilerTag = "Character Prepass";

    public CharacterPrepassPass(CharacterPrepassFeature.CharacterPrepassSettings settings)
    {
        _settings = settings;
        _gbufferHandle.Init(_settings.gbufferATextureName);
        _gbufferPropertyId = Shader.PropertyToID(_settings.gbufferATextureName);

        _filtering = new FilteringSettings(
            _settings.renderQueueRange,
            _settings.layerMask
        );
    }

    public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
    {
        // 计算 RT 尺寸（可根据 resolutionScale 缩小）
        var desc = renderingData.cameraData.cameraTargetDescriptor;
        desc.depthBufferBits = 0;
        desc.msaaSamples = 1;

        if (_settings.resolutionScale < 1f)
        {
            desc.width  = Mathf.Max(1, Mathf.RoundToInt(desc.width  * _settings.resolutionScale));
            desc.height = Mathf.Max(1, Mathf.RoundToInt(desc.height * _settings.resolutionScale));
        }

        // 创建 RT
        RenderingUtils.ReAllocateIfNeeded(ref _gbufferRT, desc, FilterMode.Bilinear, TextureWrapMode.Clamp, name: _settings.gbufferATextureName);

        // 设置本 Pass 的 RenderTarget
        ConfigureTarget(_gbufferRT);
        ConfigureClear(ClearFlag.Color, Color.clear);
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        if (_gbufferRT == null)
            return;

        var cmd = CommandBufferPool.Get(_profilerTag);

        using (new ProfilingScope(cmd, new ProfilingSampler(_profilerTag)))
        {
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();

            // 创建 DrawingSettings，只使用 LightMode = "CharacterPrepass" 的 Pass
            var sortFlags = renderingData.cameraData.defaultOpaqueSortFlags;
            var drawingSettings = CreateDrawingSettings(s_CharacterPrepassTag, ref renderingData, sortFlags);

            // 真正执行绘制
            context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref _filtering);

            // 将 RT 暴露给 Shader 采样
            cmd.SetGlobalTexture(_gbufferPropertyId, _gbufferRT);
        }

        context.ExecuteCommandBuffer(cmd);
        CommandBufferPool.Release(cmd);
    }

    public override void OnCameraCleanup(CommandBuffer cmd)
    {
        // 如果不想每帧释放，可以保留；模板里简单些就留着 RT
        // 这里就不释放 _gbufferRT，让它一直存在
    }
}
