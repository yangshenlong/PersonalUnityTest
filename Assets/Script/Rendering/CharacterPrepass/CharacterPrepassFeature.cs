using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

/// <summary>
/// CharacterPrepassFeature
/// - 挂在 URP Renderer 上，用来插入一个自定义的 Character Prepass。
/// - 这个 Prepass 会：
///   1. 使用 LightMode = "CharacterPrepass" 的 Pass，
///   2. 将角色渲染到一个中间 RT（_CharacterGBufferA），
///   3. 供后续角色 Composite Pass 采样使用。
/// </summary>

public class CharacterPrepassFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class CharacterPrepassSettings
    {
        /// <summary>
        /// 这个 Pass 在整个渲染流程中的插入时机。
        /// 一般放在 BeforeRenderingOpaques（不透明物体前）比较常见。
        /// </summary>
        public RenderPassEvent renderPassEvent = RenderPassEvent.BeforeRenderingOpaques;

        /// <summary>
        /// 预通道输出的RT名称
        /// 需要与 Shader 中的 _CharacterGBufferA 变量匹配
        /// </summary>
        public string gbufferATextureName = "_CharacterGBufferA";

        /// <summary>
        /// 目标 RT 的分辨率缩放（1 表示全分辨率）。
        /// </summary>
        [Range(0.25f, 1f)]
        public float resolutionScale = 1f;

        /// <summary>
        /// 使用哪个渲染队列范围（一般角色是 Opaque 或 AlphaTest）。
        /// </summary>
        public RenderQueueRange renderQueueRange = RenderQueueRange.opaque;

        /// <summary>
        /// 用于过滤 Layer（哪些物体会参与这个 Prepass）。
        /// 建议你专门给角色开一个层，然后这里选那一层。
        /// </summary>
        public LayerMask layerMask = ~0;
    }

    public CharacterPrepassSettings settings = new CharacterPrepassSettings();

    CharacterPrepassPass _pass;

    public override void Create()
    {
        _pass = new CharacterPrepassPass(settings);
        _pass.renderPassEvent = settings.renderPassEvent;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (_pass == null) return;

        renderer.EnqueuePass(_pass);
    }
}