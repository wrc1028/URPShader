Shader "Unlit/Function"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            struct appdata
            {
                half2 texcoord : TEXCOORD0;
                half4 vertex : POSITION;
            };

            struct v2f
            {
                half2 uv : TEXCOORD0;
                half4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            half4 _MainTex_ST;
            float4 _MainLightPosition;

            half3 ComtomLight(half3 Albedo, half3 IrisWorldNormal, half3 ViewDirection, half Metallic, half Smoothness, half SpecularMask, out float3 FinalColor)
            {
                half3 diffuseColor = Albedo * (1 - Metallic);
                half3 specularColor = Albedo * Metallic;
                half3 lightDir = _MainLightPosition.xyz;
                half3 viewDir = normalize(ViewDirection);
                half3 worldNormal = normalize(IrisWorldNormal);
                half3 halfDir = normalize(lightDir + viewDir);

                half Roughness = 1 - Smoothness;
                // dot value
                half NdotV = saturate(dot(worldNormal, viewDir));
                half NdotL = saturate(dot(worldNormal, lightDir));
                half NdotH = saturate(dot(worldNormal, halfDir));
                half LdotH = saturate(dot(lightDir, halfDir));
                half VdotH = saturate(dot(viewDir, halfDir));
                // disney color
                half FD90 = 0.5 + 2 * LdotH * LdotH * Roughness;
                half FdV = 1 + (FD90 - 1) * (1 - NdotV) * (1 - NdotV) * (1 - NdotV) * (1 - NdotV) * (1 - NdotV);
                half FdL = 1 + (FD90 - 1) * (1 - NdotL) * (1 - NdotL) * (1 - NdotL) * (1 - NdotL) * (1 - NdotL);
                half3 diffuse = diffuseColor * (1.0 * FdV * FdL);
                // D_GTR2
                half a2 = Roughness * Roughness;
                half cos2th = NdotH * NdotH;
                half den = (1.0 + (a2 - 1.0) * cos2th);
                half D_GTR2 = a2 / (3.14159265 * den * den);
                // F_Schlick
                half3 F_Schlick = specularColor + (1 - specularColor) * (1 - VdotH) * (1 - VdotH)  * (1 - VdotH)  * (1 - VdotH)  * (1 - VdotH);
                // G_GGX
                half alphaG = (0.5 + Roughness / 2) * (0.5 + Roughness / 2);
                half alphaG2 = alphaG * alphaG;
                half b2 = NdotV * NdotV;
                half G_GGX =  1 / (NdotV + sqrt(alphaG2 + b2 - alphaG2 * b2));
                // GGX specular
                half3 specular = D_GTR2 * F_Schlick * (saturate(G_GGX/(4 * NdotL * VdotH)));
                FinalColor = diffuse + specular * SpecularMask;
            }

            void OffsetUV(half4 OriginUV, half3 ViewDir_W, half3 CorneaNormal_W, half HeightValue, half HeightWeight, half IOR, out float UV)
            {
                half3 refractDir = refract(-ViewDir_W, CorneaNormal_W, 1.0 / IOR);
                half3 forwardDir = mul(unity_ObjectToWorld, half4(0, 0, 1, 0)).xyz;
                half cosAlpha = dot(-refractDir, forwardDir);
                half length = HeightValue / max(0.01, cosAlpha);
                half3 offset = refractDir * length;
                half2 uvOffset = mul(unity_WorldToObject, half4(offset, 0)).xy;
                UV = OriginUV.xy + HeightWeight * half2(-1, 1) * uvOffset;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half4 col = tex2D(_MainTex, i.uv);
                return half4(col);
            }
            ENDCG
        }
    }
}
