using System.Collections.Generic;
#if UNITY_EDITOR
using UnityEditor;

#endif
using UnityEngine;
using UnityEngine.Rendering;

 
[CreateAssetMenu(fileName = "OverDrawRendererData", menuName = "Renderering/OverDrawRendererData", order = 2)]
public class OverDrawRendererData : UnityEngine.Rendering.Universal.ScriptableRendererData
{
    [SerializeField]
    private Material m_OverDrawQuad;
    [SerializeField]
    private Material m_OverDrawTransparent;
 
 
    public Material overDrawQuad => m_OverDrawQuad;
    public Material overDrawTransparent => m_OverDrawTransparent;
 
    protected override UnityEngine.Rendering.Universal.ScriptableRenderer Create()
    {
        return new OverDrawRenderer(this);
    }
}
 
public class OverDrawRenderer : UnityEngine.Rendering.Universal.ScriptableRenderer
{
    private OverDrawRenderPass m_OverDrawRenderQuadPass;
    private OverDrawRenderPass m_OverDrawRenderTransparentPass;
    public OverDrawRenderer(UnityEngine.Rendering.Universal.ScriptableRendererData data) : base(data)
    {
        m_OverDrawRenderQuadPass = new OverDrawRenderPass(SortingCriteria.CommonOpaque, RenderQueueRange.opaque,(data as OverDrawRendererData).overDrawQuad);
        m_OverDrawRenderTransparentPass = new OverDrawRenderPass(SortingCriteria.CommonTransparent, RenderQueueRange.transparent, (data as OverDrawRendererData).overDrawTransparent);
    }
    public override void Setup(ScriptableRenderContext context, ref UnityEngine.Rendering.Universal.RenderingData renderingData)
    {
            //绘制不透明物体overdraw
            EnqueuePass(m_OverDrawRenderQuadPass);
            //绘制半透明物体overdraw
            EnqueuePass(m_OverDrawRenderTransparentPass);
    }
}
 
public class OverDrawRenderPass : UnityEngine.Rendering.Universal.ScriptableRenderPass
{
    private SortingCriteria m_Criteria;
    private Material m_OverDrawMaterial;
    private FilteringSettings m_FilteringSettings;
    private RenderStateBlock  m_RenderStateBlock;
    private List<ShaderTagId> m_ShaderTagIds = new List<ShaderTagId>()
    {
        new ShaderTagId("SRPDefaultUnlit"),
        new ShaderTagId("LightweightForward"),
    };
    public OverDrawRenderPass(SortingCriteria criteria, RenderQueueRange renderQueueRange, Material overdrawMaterial)
    {
        this.m_Criteria = criteria;
        this.m_OverDrawMaterial = overdrawMaterial;
        this.m_FilteringSettings = new FilteringSettings(renderQueueRange);
        this.m_RenderStateBlock = new RenderStateBlock(RenderStateMask.Nothing);
        
    }
    public override void Execute(ScriptableRenderContext context, ref UnityEngine.Rendering.Universal.RenderingData renderingData)
    {
        var drawingSettings = CreateDrawingSettings(m_ShaderTagIds, ref renderingData, this.m_Criteria);
        if(!renderingData.cameraData.isSceneViewCamera)
            drawingSettings.overrideMaterial = m_OverDrawMaterial;
        CommandBuffer cmd = CommandBufferPool.Get("Name");
        using(new ProfilingSample(cmd, "Name"))
        {
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref m_FilteringSettings, ref m_RenderStateBlock);
        }
        context.ExecuteCommandBuffer(cmd);
        CommandBufferPool.Release(cmd);
    }
}
#if UNITY_EDITOR
[CustomEditor(typeof(OverDrawRendererData))]
public class OverDrawRendererDataEditor : UnityEditor.Rendering.Universal.ScriptableRendererDataEditor
{
    public override void OnInspectorGUI()
    {
 
        serializedObject.Update();
        EditorGUILayout.PropertyField(serializedObject.FindProperty("m_OverDrawQuad"));
        EditorGUILayout.PropertyField(serializedObject.FindProperty("m_OverDrawTransparent"));
        serializedObject.ApplyModifiedProperties();
        base.OnInspectorGUI();
    }
}
#endif