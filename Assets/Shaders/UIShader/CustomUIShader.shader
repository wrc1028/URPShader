Shader "Unlit/CustomUIShader"
{
    Properties
    {
        [PerRendererData] _MainTex ("Texture", 2D) = "white" {}
        [Header(Halo)]
        [Toggle(HALO_ON)] _UseHalo ("Use Halo", Float) = 0
        _HaloColor ("Halo Color", Color) = (1, 1, 1, 1)
        _HaloTiling ("Halo Tiling & Offset", vector) = (1, 1, 0, 0)
        _HaloPower ("Halo Power", Range(0.01, 1)) = 0.5
        [Header(Decal)]
        [Toggle(DECALTEX_ON)] _UseDecal ("Use Decal", Float) = 0
        _DecalTex ("Decal", 2D) = "white" {}
        _DecalColor ("Decal Color", Color) = (1, 1, 1, 1)
        [Header(Stencil)]
        _StencilComp ("Stencil Comparison", Float) = 8
		_Stencil ("Stencil ID", Float) = 0
		_StencilOp ("Stencil Operation", Float) = 0
		_StencilWriteMask ("Stencil Write Mask", Float) = 255
		_StencilReadMask ("Stencil Read Mask", Float) = 255
        _ColorMask ("Color Mask", Float) = 15
        [Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip ("Use Alpha Clip", Float) = 0
    }
    SubShader
    {
		Tags
		{
			"Queue"="Transparent"
			"IgnoreProjector"="True"
			"RenderType"="Transparent"
			"PreviewType"="Plane"
			"CanUseSpriteAtlas"="True"
		}
		Stencil
		{
			Ref [_Stencil]
			Comp [_StencilComp]
			Pass [_StencilOp]
			ReadMask [_StencilReadMask]
			WriteMask [_StencilWriteMask]
		}
        
        Cull Off
		Lighting Off
		ZWrite Off
		ZTest [unity_GUIZTestMode]
		Blend SrcAlpha OneMinusSrcAlpha
		ColorMask [_ColorMask]

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ UNITY_UI_ALPHACLIP
            #pragma shader_feature _ HALO_ON
            #pragma shader_feature _ DECALTEX_ON

            #include "UnityUI.cginc"
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            fixed4 _TextureSampleAdd;
            float4 _ClipRect;

            float4 _HaloColor;
            float4 _HaloTiling;
            float _HaloPower;

            sampler2D _DecalTex;
            float4 _DecalTex_ST;
            float4 _DecalColor;
            float4 _DecalTiling;
            

            struct a2v
            {
                float4 vertex : POSITION;
                float4 color : COLOR;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
		    struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 color : COLOR;
               	float4 uv : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
            };
            v2f vert(a2v IN)
            {
                v2f OUT;
                UNITY_SETUP_INSTANCE_ID(IN);
			    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
                OUT.vertex = UnityObjectToClipPos(IN.vertex);
                OUT.color = IN.color;
                OUT.uv.xy = IN.texcoord;
                OUT.uv.zw = TRANSFORM_TEX(IN.texcoord, _DecalTex);
                return OUT;
            }
            fixed4 frag(v2f IN) : SV_Target
            {
                // 光晕
                half2 haloUV = (IN.uv.xy - _HaloTiling.zw) * _HaloTiling.xy;
                half dis = 1 - saturate(distance(haloUV, half2(0.5, 0.5) * _HaloTiling.xy));
                half power = smoothstep(0, _HaloPower, dis);
                // 贴画
                half2 decalUV = IN.uv.zw;
                half4 decalColor = tex2D(_DecalTex, decalUV) * _DecalColor;
                // decalColor.rgb = decalColor.a == 0 ? half3(0.5, 0.5, 0.5) : decalColor.rgb;
                // 主帖图
                half4 texColor = tex2D(_MainTex,IN.uv.xy) * IN.color;
                half finalAlpha = texColor.a;

                half3 finalColor = texColor.rgb;

                #ifdef HALO_ON
                    finalColor = saturate(finalColor + power * _HaloColor.rgb);
                #endif

                #ifdef DECALTEX_ON
                    // finalColor = finalColor * (1 + decalColor.rgb * decalColor.a);
                    finalColor.r = finalColor.r <= 0.5 ? finalColor.r * decalColor.r * 2 : 
                        1 - (1 - finalColor.r) * (1 - decalColor.r) * 2;
                    finalColor.g = finalColor.g <= 0.5 ? finalColor.g * decalColor.g * 2 : 
                        1 - (1 - finalColor.g) * (1 - decalColor.g) * 2;
                    finalColor.b = finalColor.b <= 0.5 ? finalColor.b * decalColor.b * 2 : 
                        1 - (1 - finalColor.b) * (1 - decalColor.b) * 2;
                #endif    

                #ifdef UNITY_UI_ALPHACLIP
                    clip (finalAlpha - 0.001);
                #endif

                return half4(finalColor, finalAlpha);
		    }
            ENDCG
        }
    }
}
