using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace UnityEngine.Rendering.Universal
{
    [System.Serializable, VolumeComponentMenu("Custom/DistortScreen")]
    public class DistortScreen : VolumeComponent, IPostProcessComponent
    {
        [Tooltip("Strength of the screen distortion.")]
        public MinFloatParameter intensity = new MinFloatParameter(0f, 0f);
        public bool IsActive() => active && intensity.value > 0.0f;
        public bool IsTileCompatible() => false;
    }
}