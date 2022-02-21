using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CalculateOverdraw : MonoBehaviour
{
    public ComputeShader overdrawCount;
    public RenderTexture rt;
    private void Start()
    {
        Debug.Log(GetOverdrawNum(rt));
        Debug.Log(GetOverdrawNum(rt));
    }
    
    private float GetOverdrawNum(RenderTexture rt)
    {
        float totalNum = 0;
        overdrawCount.SetTexture(0, "_RenderTexture", rt);
        overdrawCount.SetInt("_Height", rt.height);
        float[] overdrawNum =  new float[rt.width * rt.height];
        ComputeBuffer result = new ComputeBuffer(overdrawNum.Length, sizeof(float));
        result.SetData(overdrawNum);
        overdrawCount.SetBuffer(0, "Result", result);
        overdrawCount.Dispatch(0, Mathf.CeilToInt((float)rt.width / 8), Mathf.CeilToInt((float)rt.height / 8), 1);
        result.GetData(overdrawNum);
        foreach (var num in overdrawNum)
        {
            totalNum += num;
        }
        result.Dispose();
        result.Release();
        return (float)totalNum / overdrawNum.Length;
    }
}
