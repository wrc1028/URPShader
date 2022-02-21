Shader "Eye_ShaderGraph"
{
    Properties
    {
        [NoScaleOffset]_Albedo_RGB_("Albedo(RGB)", 2D) = "white" {}
        [NoScaleOffset]_CorneaNormalMap("CorneaNormalMap", 2D) = "bump" {}
        [NoScaleOffset]_CorneaMSO("CorneaMSHM", 2D) = "white" {}
        _CorneaMetallic("CorneaMetallic", Range(0, 1)) = 1
        _CorneaSmoothness("CorneaSmoothness", Range(0, 1)) = 1
        _HeightWeight("HeightWeight", Range(0, 1)) = 1
        [NoScaleOffset]_IrisNormalMap("IrisNormalMap", 2D) = "bump" {}
        [NoScaleOffset]_IrisMSO("IrisMSO", 2D) = "white" {}
        _IrisMetallic("IrisMetallic", Range(0, 1)) = 1
        _IrisSmoothness("IrisSmoothness", Range(0, 1)) = 1
        _IrisAOStrength("IrisAOStrength", Range(0, 1)) = 1
        [HideInInspector][NoScaleOffset]unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Opaque"
            "UniversalMaterialType" = "Lit"
            "Queue"="Geometry"
        }
        Pass
        {
            Name "Universal Forward"
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            // Render State
            Cull Back
        Blend One Zero
        ZTest LEqual
        ZWrite On

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile_fog
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            #pragma multi_compile _ _SCREEN_SPACE_OCCLUSION
        #pragma multi_compile _ LIGHTMAP_ON
        #pragma multi_compile _ DIRLIGHTMAP_COMBINED
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
        #pragma multi_compile _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS _ADDITIONAL_OFF
        #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
        #pragma multi_compile _ _SHADOWS_SOFT
        #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
        #pragma multi_compile _ SHADOWS_SHADOWMASK
            // GraphKeywords: <None>

            // Defines
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD0
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_TANGENT_WS
            #define VARYINGS_NEED_TEXCOORD0
            #define VARYINGS_NEED_VIEWDIRECTION_WS
            #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_FORWARD
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            float4 uv0 : TEXCOORD0;
            float4 uv1 : TEXCOORD1;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            float4 tangentWS;
            float4 texCoord0;
            float3 viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            float2 lightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            float3 sh;
            #endif
            float4 fogFactorAndVertexLight;
            float4 shadowCoord;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 TangentSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 WorldSpaceTangent;
            float3 ObjectSpaceBiTangent;
            float3 WorldSpaceBiTangent;
            float3 WorldSpaceViewDirection;
            float4 uv0;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float3 interp1 : TEXCOORD1;
            float4 interp2 : TEXCOORD2;
            float4 interp3 : TEXCOORD3;
            float3 interp4 : TEXCOORD4;
            #if defined(LIGHTMAP_ON)
            float2 interp5 : TEXCOORD5;
            #endif
            #if !defined(LIGHTMAP_ON)
            float3 interp6 : TEXCOORD6;
            #endif
            float4 interp7 : TEXCOORD7;
            float4 interp8 : TEXCOORD8;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            output.interp3.xyzw =  input.texCoord0;
            output.interp4.xyz =  input.viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            output.interp5.xy =  input.lightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.interp6.xyz =  input.sh;
            #endif
            output.interp7.xyzw =  input.fogFactorAndVertexLight;
            output.interp8.xyzw =  input.shadowCoord;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            output.texCoord0 = input.interp3.xyzw;
            output.viewDirectionWS = input.interp4.xyz;
            #if defined(LIGHTMAP_ON)
            output.lightmapUV = input.interp5.xy;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.sh = input.interp6.xyz;
            #endif
            output.fogFactorAndVertexLight = input.interp7.xyzw;
            output.shadowCoord = input.interp8.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float4 _Albedo_RGB__TexelSize;
        float4 _CorneaNormalMap_TexelSize;
        float4 _CorneaMSO_TexelSize;
        float _CorneaMetallic;
        float _CorneaSmoothness;
        float _HeightWeight;
        float4 _IrisNormalMap_TexelSize;
        float4 _IrisMSO_TexelSize;
        float _IrisMetallic;
        float _IrisSmoothness;
        float _IrisAOStrength;
        CBUFFER_END

        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_Albedo_RGB_);
        SAMPLER(sampler_Albedo_RGB_);
        TEXTURE2D(_CorneaNormalMap);
        SAMPLER(sampler_CorneaNormalMap);
        TEXTURE2D(_CorneaMSO);
        SAMPLER(sampler_CorneaMSO);
        TEXTURE2D(_IrisNormalMap);
        SAMPLER(sampler_IrisNormalMap);
        TEXTURE2D(_IrisMSO);
        SAMPLER(sampler_IrisMSO);

            // Graph Functions
            
        void Unity_Normalize_float3(float3 In, out float3 Out)
        {
            Out = normalize(In);
        }

        void UVOffset_float(float3 corneaNormalW, float3 viewDirW, float3 forwardDir, float heightData, out float2 offsetUV, out float3 viewRefrDirW){
            half IOR = 1.33f;
            viewRefrDirW = refract(-viewDirW, corneaNormalW, 1.0f / IOR);
            half cosAlpha = dot(-viewRefrDirW, normalize(forwardDir));
            half distance = heightData / cosAlpha;
            half3 offsetW = viewRefrDirW * distance;
            offsetUV = mul(unity_WorldToObject, offsetW).xy;
        }

        void Unity_Multiply_float(float2 A, float2 B, out float2 Out)
        {
            Out = A * B;
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_Add_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A + B;
        }

        void Unity_Negate_float3(float3 In, out float3 Out)
        {
            Out = -1 * In;
        }

        void CustomLight_float(float3 Albedo, float3 ViewDirection, float3 IrisWorldNormal, float Metallic, float Smoothness, float SpecularMask, out float3 FinalColor){
            half3 diffuseColor = Albedo * (1 - Metallic);
            half3 specularColor = Albedo * Metallic;
            half3 lightDir = normalize(_MainLightPosition.xyz);
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
            half FD90 = 0.5 + 2 * VdotH * VdotH * Roughness;
            half FdV = 1 + (FD90 - 1) * (1 - NdotV) * (1 - NdotV) * (1 - NdotV) * (1 - NdotV) * (1 - NdotV);
            half FdL = 1 + (FD90 - 1) * (1 - NdotL) * (1 - NdotL) * (1 - NdotL) * (1 - NdotL) * (1 - NdotL);
            half3 diffuse = diffuseColor * FdV * FdL;
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
            half3 specular = SpecularMask * D_GTR2 * F_Schlick * (saturate(G_GGX/(4 * NdotL * VdotH)));
            FinalColor = specular + diffuse;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float3 BaseColor;
            float3 NormalTS;
            float3 Emission;
            float Metallic;
            float Smoothness;
            float Occlusion;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            UnityTexture2D _Property_f2272dd4998b46269e54d957e7b8483e_Out_0 = UnityBuildTexture2DStructNoScale(_Albedo_RGB_);
            float4 _UV_f2ce5ad282824f3c9efacac42b9d35e1_Out_0 = IN.uv0;
            UnityTexture2D _Property_945106df349f4dc1af007b3053b22f1d_Out_0 = UnityBuildTexture2DStructNoScale(_CorneaNormalMap);
            float4 _SampleTexture2D_1df191bad2fc488985b3a30ba48d8224_RGBA_0 = SAMPLE_TEXTURE2D(_Property_945106df349f4dc1af007b3053b22f1d_Out_0.tex, _Property_945106df349f4dc1af007b3053b22f1d_Out_0.samplerstate, IN.uv0.xy);
            _SampleTexture2D_1df191bad2fc488985b3a30ba48d8224_RGBA_0.rgb = UnpackNormal(_SampleTexture2D_1df191bad2fc488985b3a30ba48d8224_RGBA_0);
            float _SampleTexture2D_1df191bad2fc488985b3a30ba48d8224_R_4 = _SampleTexture2D_1df191bad2fc488985b3a30ba48d8224_RGBA_0.r;
            float _SampleTexture2D_1df191bad2fc488985b3a30ba48d8224_G_5 = _SampleTexture2D_1df191bad2fc488985b3a30ba48d8224_RGBA_0.g;
            float _SampleTexture2D_1df191bad2fc488985b3a30ba48d8224_B_6 = _SampleTexture2D_1df191bad2fc488985b3a30ba48d8224_RGBA_0.b;
            float _SampleTexture2D_1df191bad2fc488985b3a30ba48d8224_A_7 = _SampleTexture2D_1df191bad2fc488985b3a30ba48d8224_RGBA_0.a;
            float3x3 Transform_81fd3c4d62b740dcad630ce63f9c8c5e_transposeTangent = transpose(float3x3(IN.WorldSpaceTangent, IN.WorldSpaceBiTangent, IN.WorldSpaceNormal));
            float3 _Transform_81fd3c4d62b740dcad630ce63f9c8c5e_Out_1 = normalize(mul(Transform_81fd3c4d62b740dcad630ce63f9c8c5e_transposeTangent, (_SampleTexture2D_1df191bad2fc488985b3a30ba48d8224_RGBA_0.xyz).xyz).xyz);
            float3 _Normalize_1eb23240f669476ca79425eedf8dc329_Out_1;
            Unity_Normalize_float3(_Transform_81fd3c4d62b740dcad630ce63f9c8c5e_Out_1, _Normalize_1eb23240f669476ca79425eedf8dc329_Out_1);
            float3 _Normalize_d83cd5e2983e4304acf00837d643a742_Out_1;
            Unity_Normalize_float3(IN.WorldSpaceViewDirection, _Normalize_d83cd5e2983e4304acf00837d643a742_Out_1);
            float3 _Vector3_bc75bd5c39614653948984506910d295_Out_0 = float3(0, 0, 1);
            float3 _Transform_5f432632021a4eb8969f6ccc45d88429_Out_1 = TransformObjectToWorldDir(_Vector3_bc75bd5c39614653948984506910d295_Out_0.xyz);
            float3 _Normalize_568ee998a3d542bfadc1c726618da559_Out_1;
            Unity_Normalize_float3(_Transform_5f432632021a4eb8969f6ccc45d88429_Out_1, _Normalize_568ee998a3d542bfadc1c726618da559_Out_1);
            UnityTexture2D _Property_5b57865f0e864fc1929a6314c10fe626_Out_0 = UnityBuildTexture2DStructNoScale(_CorneaMSO);
            float4 _SampleTexture2D_649d6832a8084d32b59612720f49c1e0_RGBA_0 = SAMPLE_TEXTURE2D(_Property_5b57865f0e864fc1929a6314c10fe626_Out_0.tex, _Property_5b57865f0e864fc1929a6314c10fe626_Out_0.samplerstate, IN.uv0.xy);
            float _SampleTexture2D_649d6832a8084d32b59612720f49c1e0_R_4 = _SampleTexture2D_649d6832a8084d32b59612720f49c1e0_RGBA_0.r;
            float _SampleTexture2D_649d6832a8084d32b59612720f49c1e0_G_5 = _SampleTexture2D_649d6832a8084d32b59612720f49c1e0_RGBA_0.g;
            float _SampleTexture2D_649d6832a8084d32b59612720f49c1e0_B_6 = _SampleTexture2D_649d6832a8084d32b59612720f49c1e0_RGBA_0.b;
            float _SampleTexture2D_649d6832a8084d32b59612720f49c1e0_A_7 = _SampleTexture2D_649d6832a8084d32b59612720f49c1e0_RGBA_0.a;
            float2 _UVOffsetCustomFunction_1cbea4bef08a48bbab888ac658ec6e57_offsetUV_1;
            float3 _UVOffsetCustomFunction_1cbea4bef08a48bbab888ac658ec6e57_viewRefrDirW_7;
            UVOffset_float(_Normalize_1eb23240f669476ca79425eedf8dc329_Out_1, _Normalize_d83cd5e2983e4304acf00837d643a742_Out_1, _Normalize_568ee998a3d542bfadc1c726618da559_Out_1, _SampleTexture2D_649d6832a8084d32b59612720f49c1e0_B_6, _UVOffsetCustomFunction_1cbea4bef08a48bbab888ac658ec6e57_offsetUV_1, _UVOffsetCustomFunction_1cbea4bef08a48bbab888ac658ec6e57_viewRefrDirW_7);
            float2 _Vector2_d49f235028434be6896b66ee08e5a431_Out_0 = float2(-1, 1);
            float2 _Multiply_046dc79e17e84106b267dcae69582837_Out_2;
            Unity_Multiply_float(_UVOffsetCustomFunction_1cbea4bef08a48bbab888ac658ec6e57_offsetUV_1, _Vector2_d49f235028434be6896b66ee08e5a431_Out_0, _Multiply_046dc79e17e84106b267dcae69582837_Out_2);
            float _Property_570aa07405a0410fac902bc9eff6d450_Out_0 = _HeightWeight;
            float _Multiply_945b3e8a74f64ae890dc81cdc73bb8f0_Out_2;
            Unity_Multiply_float(_SampleTexture2D_649d6832a8084d32b59612720f49c1e0_A_7, _Property_570aa07405a0410fac902bc9eff6d450_Out_0, _Multiply_945b3e8a74f64ae890dc81cdc73bb8f0_Out_2);
            float2 _Multiply_6b0c35d1b44540bba75ae35f2d9e334c_Out_2;
            Unity_Multiply_float(_Multiply_046dc79e17e84106b267dcae69582837_Out_2, (_Multiply_945b3e8a74f64ae890dc81cdc73bb8f0_Out_2.xx), _Multiply_6b0c35d1b44540bba75ae35f2d9e334c_Out_2);
            float2 _Add_281fecc0ca2a44aba05b736443af6639_Out_2;
            Unity_Add_float2((_UV_f2ce5ad282824f3c9efacac42b9d35e1_Out_0.xy), _Multiply_6b0c35d1b44540bba75ae35f2d9e334c_Out_2, _Add_281fecc0ca2a44aba05b736443af6639_Out_2);
            float4 _SampleTexture2D_4ba91cdca0684350b072d7e87298412f_RGBA_0 = SAMPLE_TEXTURE2D(_Property_f2272dd4998b46269e54d957e7b8483e_Out_0.tex, _Property_f2272dd4998b46269e54d957e7b8483e_Out_0.samplerstate, _Add_281fecc0ca2a44aba05b736443af6639_Out_2);
            float _SampleTexture2D_4ba91cdca0684350b072d7e87298412f_R_4 = _SampleTexture2D_4ba91cdca0684350b072d7e87298412f_RGBA_0.r;
            float _SampleTexture2D_4ba91cdca0684350b072d7e87298412f_G_5 = _SampleTexture2D_4ba91cdca0684350b072d7e87298412f_RGBA_0.g;
            float _SampleTexture2D_4ba91cdca0684350b072d7e87298412f_B_6 = _SampleTexture2D_4ba91cdca0684350b072d7e87298412f_RGBA_0.b;
            float _SampleTexture2D_4ba91cdca0684350b072d7e87298412f_A_7 = _SampleTexture2D_4ba91cdca0684350b072d7e87298412f_RGBA_0.a;
            float3 _Negate_ce3117a8d97c4c1f8212b0e54a18ea50_Out_1;
            Unity_Negate_float3(_UVOffsetCustomFunction_1cbea4bef08a48bbab888ac658ec6e57_viewRefrDirW_7, _Negate_ce3117a8d97c4c1f8212b0e54a18ea50_Out_1);
            UnityTexture2D _Property_046fbc8d106b4ee79400aa319a6bde0c_Out_0 = UnityBuildTexture2DStructNoScale(_IrisNormalMap);
            float4 _SampleTexture2D_792b1569ebda4cf0bc132763067454ad_RGBA_0 = SAMPLE_TEXTURE2D(_Property_046fbc8d106b4ee79400aa319a6bde0c_Out_0.tex, _Property_046fbc8d106b4ee79400aa319a6bde0c_Out_0.samplerstate, _Add_281fecc0ca2a44aba05b736443af6639_Out_2);
            _SampleTexture2D_792b1569ebda4cf0bc132763067454ad_RGBA_0.rgb = UnpackNormal(_SampleTexture2D_792b1569ebda4cf0bc132763067454ad_RGBA_0);
            float _SampleTexture2D_792b1569ebda4cf0bc132763067454ad_R_4 = _SampleTexture2D_792b1569ebda4cf0bc132763067454ad_RGBA_0.r;
            float _SampleTexture2D_792b1569ebda4cf0bc132763067454ad_G_5 = _SampleTexture2D_792b1569ebda4cf0bc132763067454ad_RGBA_0.g;
            float _SampleTexture2D_792b1569ebda4cf0bc132763067454ad_B_6 = _SampleTexture2D_792b1569ebda4cf0bc132763067454ad_RGBA_0.b;
            float _SampleTexture2D_792b1569ebda4cf0bc132763067454ad_A_7 = _SampleTexture2D_792b1569ebda4cf0bc132763067454ad_RGBA_0.a;
            float3x3 Transform_41871579e7634c1f966bf97f3b48c39c_transposeTangent = transpose(float3x3(IN.WorldSpaceTangent, IN.WorldSpaceBiTangent, IN.WorldSpaceNormal));
            float3 _Transform_41871579e7634c1f966bf97f3b48c39c_Out_1 = mul(Transform_41871579e7634c1f966bf97f3b48c39c_transposeTangent, (_SampleTexture2D_792b1569ebda4cf0bc132763067454ad_RGBA_0.xyz).xyz).xyz;
            UnityTexture2D _Property_32eb3ff548c74cf79bb1b0b0bd0cad19_Out_0 = UnityBuildTexture2DStructNoScale(_IrisMSO);
            float4 _SampleTexture2D_bef70bc2a771432cb911143fff476c4f_RGBA_0 = SAMPLE_TEXTURE2D(_Property_32eb3ff548c74cf79bb1b0b0bd0cad19_Out_0.tex, _Property_32eb3ff548c74cf79bb1b0b0bd0cad19_Out_0.samplerstate, _Add_281fecc0ca2a44aba05b736443af6639_Out_2);
            float _SampleTexture2D_bef70bc2a771432cb911143fff476c4f_R_4 = _SampleTexture2D_bef70bc2a771432cb911143fff476c4f_RGBA_0.r;
            float _SampleTexture2D_bef70bc2a771432cb911143fff476c4f_G_5 = _SampleTexture2D_bef70bc2a771432cb911143fff476c4f_RGBA_0.g;
            float _SampleTexture2D_bef70bc2a771432cb911143fff476c4f_B_6 = _SampleTexture2D_bef70bc2a771432cb911143fff476c4f_RGBA_0.b;
            float _SampleTexture2D_bef70bc2a771432cb911143fff476c4f_A_7 = _SampleTexture2D_bef70bc2a771432cb911143fff476c4f_RGBA_0.a;
            float _Property_19c6cce68ffb453782822b1c2bc861fa_Out_0 = _IrisMetallic;
            float _Multiply_570dfaa895634f2e837996a268d375ee_Out_2;
            Unity_Multiply_float(_SampleTexture2D_bef70bc2a771432cb911143fff476c4f_R_4, _Property_19c6cce68ffb453782822b1c2bc861fa_Out_0, _Multiply_570dfaa895634f2e837996a268d375ee_Out_2);
            float _Property_1f9893e43b854dc2b17d4ebecc5348e7_Out_0 = _IrisSmoothness;
            float _Multiply_32f96b612cc4403b990ddbe19baf2c02_Out_2;
            Unity_Multiply_float(_SampleTexture2D_bef70bc2a771432cb911143fff476c4f_G_5, _Property_1f9893e43b854dc2b17d4ebecc5348e7_Out_0, _Multiply_32f96b612cc4403b990ddbe19baf2c02_Out_2);
            float _Property_769fb7698e034178be9008a3e607c8f1_Out_0 = _IrisAOStrength;
            float _Multiply_8c2ecdb7fafe4f5d9667d4cd109d7bd4_Out_2;
            Unity_Multiply_float(_SampleTexture2D_bef70bc2a771432cb911143fff476c4f_B_6, _Property_769fb7698e034178be9008a3e607c8f1_Out_0, _Multiply_8c2ecdb7fafe4f5d9667d4cd109d7bd4_Out_2);
            float3 _CustomLightCustomFunction_068f9cb549e342bda035c1b2b3ba0676_FinalColor_0;
            CustomLight_float((_SampleTexture2D_4ba91cdca0684350b072d7e87298412f_RGBA_0.xyz), _Negate_ce3117a8d97c4c1f8212b0e54a18ea50_Out_1, _Transform_41871579e7634c1f966bf97f3b48c39c_Out_1, _Multiply_570dfaa895634f2e837996a268d375ee_Out_2, _Multiply_32f96b612cc4403b990ddbe19baf2c02_Out_2, _Multiply_8c2ecdb7fafe4f5d9667d4cd109d7bd4_Out_2, _CustomLightCustomFunction_068f9cb549e342bda035c1b2b3ba0676_FinalColor_0);
            float _Property_b33ce5a648714f609015b60d88056592_Out_0 = _CorneaMetallic;
            float _Multiply_21523663351549588bbfcc46f5a9dc84_Out_2;
            Unity_Multiply_float(_SampleTexture2D_649d6832a8084d32b59612720f49c1e0_R_4, _Property_b33ce5a648714f609015b60d88056592_Out_0, _Multiply_21523663351549588bbfcc46f5a9dc84_Out_2);
            float _Property_5068534489bb419d9daa71fcb4e08755_Out_0 = _CorneaSmoothness;
            float _Multiply_65a14cb177fc46abb116eb0bcd71eb9a_Out_2;
            Unity_Multiply_float(_SampleTexture2D_649d6832a8084d32b59612720f49c1e0_G_5, _Property_5068534489bb419d9daa71fcb4e08755_Out_0, _Multiply_65a14cb177fc46abb116eb0bcd71eb9a_Out_2);
            surface.BaseColor = _CustomLightCustomFunction_068f9cb549e342bda035c1b2b3ba0676_FinalColor_0;
            surface.NormalTS = (_SampleTexture2D_1df191bad2fc488985b3a30ba48d8224_RGBA_0.xyz);
            surface.Emission = float3(0, 0, 0);
            surface.Metallic = _Multiply_21523663351549588bbfcc46f5a9dc84_Out_2;
            surface.Smoothness = _Multiply_65a14cb177fc46abb116eb0bcd71eb9a_Out_2;
            surface.Occlusion = 1;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

        	// must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
        	float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);

        	// use bitangent on the fly like in hdrp
        	// IMPORTANT! If we ever support Flip on double sided materials ensure bitangent and tangent are NOT flipped.
            float crossSign = (input.tangentWS.w > 0.0 ? 1.0 : -1.0) * GetOddNegativeScale();
        	float3 bitang = crossSign * cross(input.normalWS.xyz, input.tangentWS.xyz);

            output.WorldSpaceNormal =            renormFactor*input.normalWS.xyz;		// we want a unit length Normal Vector node in shader graph
            output.ObjectSpaceNormal =           normalize(mul(output.WorldSpaceNormal, (float3x3) UNITY_MATRIX_M));           // transposed multiplication by inverse matrix to handle normal scale
            output.TangentSpaceNormal =          float3(0.0f, 0.0f, 1.0f);

        	// to preserve mikktspace compliance we use same scale renormFactor as was used on the normal.
        	// This is explained in section 2.2 in "surface gradient based bump mapping framework"
            output.WorldSpaceTangent =           renormFactor*input.tangentWS.xyz;
        	output.WorldSpaceBiTangent =         renormFactor*bitang;

            output.ObjectSpaceTangent =          TransformWorldToObjectDir(output.WorldSpaceTangent);
            output.ObjectSpaceBiTangent =        TransformWorldToObjectDir(output.WorldSpaceBiTangent);
            output.WorldSpaceViewDirection =     input.viewDirectionWS; //TODO: by default normalized in HD, but not in universal
            output.uv0 =                         input.texCoord0;
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBRForwardPass.hlsl"

            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }

            // Render State
            Cull Back
        Blend One Zero
        ZTest LEqual
        ZWrite On
        ColorMask 0

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            // PassKeywords: <None>
            // GraphKeywords: <None>

            // Defines
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_SHADOWCASTER
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float4 _Albedo_RGB__TexelSize;
        float4 _CorneaNormalMap_TexelSize;
        float4 _CorneaMSO_TexelSize;
        float _CorneaMetallic;
        float _CorneaSmoothness;
        float _HeightWeight;
        float4 _IrisNormalMap_TexelSize;
        float4 _IrisMSO_TexelSize;
        float _IrisMetallic;
        float _IrisSmoothness;
        float _IrisAOStrength;
        CBUFFER_END

        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_Albedo_RGB_);
        SAMPLER(sampler_Albedo_RGB_);
        TEXTURE2D(_CorneaNormalMap);
        SAMPLER(sampler_CorneaNormalMap);
        TEXTURE2D(_CorneaMSO);
        SAMPLER(sampler_CorneaMSO);
        TEXTURE2D(_IrisNormalMap);
        SAMPLER(sampler_IrisNormalMap);
        TEXTURE2D(_IrisMSO);
        SAMPLER(sampler_IrisMSO);

            // Graph Functions
            // GraphFunctions: <None>

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);





        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShadowCasterPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }

            // Render State
            Cull Back
        Blend One Zero
        ZTest LEqual
        ZWrite On
        ColorMask 0

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            // PassKeywords: <None>
            // GraphKeywords: <None>

            // Defines
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_DEPTHONLY
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float4 _Albedo_RGB__TexelSize;
        float4 _CorneaNormalMap_TexelSize;
        float4 _CorneaMSO_TexelSize;
        float _CorneaMetallic;
        float _CorneaSmoothness;
        float _HeightWeight;
        float4 _IrisNormalMap_TexelSize;
        float4 _IrisMSO_TexelSize;
        float _IrisMetallic;
        float _IrisSmoothness;
        float _IrisAOStrength;
        CBUFFER_END

        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_Albedo_RGB_);
        SAMPLER(sampler_Albedo_RGB_);
        TEXTURE2D(_CorneaNormalMap);
        SAMPLER(sampler_CorneaNormalMap);
        TEXTURE2D(_CorneaMSO);
        SAMPLER(sampler_CorneaMSO);
        TEXTURE2D(_IrisNormalMap);
        SAMPLER(sampler_IrisNormalMap);
        TEXTURE2D(_IrisMSO);
        SAMPLER(sampler_IrisMSO);

            // Graph Functions
            // GraphFunctions: <None>

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);





        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthOnlyPass.hlsl"

            ENDHLSL
        }
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Opaque"
            "UniversalMaterialType" = "Lit"
            "Queue"="Geometry"
        }
        Pass
        {
            Name "Universal Forward"
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            // Render State
            Cull Back
        Blend One Zero
        ZTest LEqual
        ZWrite On

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma multi_compile_fog
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            #pragma multi_compile _ _SCREEN_SPACE_OCCLUSION
        #pragma multi_compile _ LIGHTMAP_ON
        #pragma multi_compile _ DIRLIGHTMAP_COMBINED
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
        #pragma multi_compile _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS _ADDITIONAL_OFF
        #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
        #pragma multi_compile _ _SHADOWS_SOFT
        #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
        #pragma multi_compile _ SHADOWS_SHADOWMASK
        #pragma skip_variants LIGHTMAP_ON DIRLIGHTMAP_COMBINED  _MAIN_LIGHT_SHADOWS_CASCADE _ADDITIONAL_LIGHT_SHADOWS _SHADOWS_SOFT LIGHTMAP_SHADOW_MIXING SHADOWS_SHADOWMASK
            // GraphKeywords: <None>

            // Defines
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD0
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_TANGENT_WS
            #define VARYINGS_NEED_TEXCOORD0
            #define VARYINGS_NEED_VIEWDIRECTION_WS
            #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_FORWARD
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            float4 uv0 : TEXCOORD0;
            float4 uv1 : TEXCOORD1;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            float4 tangentWS;
            float4 texCoord0;
            float3 viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            float2 lightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            float3 sh;
            #endif
            float4 fogFactorAndVertexLight;
            float4 shadowCoord;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 TangentSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 WorldSpaceTangent;
            float3 ObjectSpaceBiTangent;
            float3 WorldSpaceBiTangent;
            float3 WorldSpaceViewDirection;
            float4 uv0;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float3 interp1 : TEXCOORD1;
            float4 interp2 : TEXCOORD2;
            float4 interp3 : TEXCOORD3;
            float3 interp4 : TEXCOORD4;
            #if defined(LIGHTMAP_ON)
            float2 interp5 : TEXCOORD5;
            #endif
            #if !defined(LIGHTMAP_ON)
            float3 interp6 : TEXCOORD6;
            #endif
            float4 interp7 : TEXCOORD7;
            float4 interp8 : TEXCOORD8;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            output.interp3.xyzw =  input.texCoord0;
            output.interp4.xyz =  input.viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            output.interp5.xy =  input.lightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.interp6.xyz =  input.sh;
            #endif
            output.interp7.xyzw =  input.fogFactorAndVertexLight;
            output.interp8.xyzw =  input.shadowCoord;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            output.texCoord0 = input.interp3.xyzw;
            output.viewDirectionWS = input.interp4.xyz;
            #if defined(LIGHTMAP_ON)
            output.lightmapUV = input.interp5.xy;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.sh = input.interp6.xyz;
            #endif
            output.fogFactorAndVertexLight = input.interp7.xyzw;
            output.shadowCoord = input.interp8.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float4 _Albedo_RGB__TexelSize;
        float4 _CorneaNormalMap_TexelSize;
        float4 _CorneaMSO_TexelSize;
        float _CorneaMetallic;
        float _CorneaSmoothness;
        float _HeightWeight;
        float4 _IrisNormalMap_TexelSize;
        float4 _IrisMSO_TexelSize;
        float _IrisMetallic;
        float _IrisSmoothness;
        float _IrisAOStrength;
        CBUFFER_END

        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_Albedo_RGB_);
        SAMPLER(sampler_Albedo_RGB_);
        TEXTURE2D(_CorneaNormalMap);
        SAMPLER(sampler_CorneaNormalMap);
        TEXTURE2D(_CorneaMSO);
        SAMPLER(sampler_CorneaMSO);
        TEXTURE2D(_IrisNormalMap);
        SAMPLER(sampler_IrisNormalMap);
        TEXTURE2D(_IrisMSO);
        SAMPLER(sampler_IrisMSO);

            // Graph Functions
            
        void Unity_Normalize_float3(float3 In, out float3 Out)
        {
            Out = normalize(In);
        }

        void UVOffset_float(float3 corneaNormalW, float3 viewDirW, float3 forwardDir, float heightData, out float2 offsetUV, out float3 viewRefrDirW){
            half IOR = 1.33f;
            viewRefrDirW = refract(-viewDirW, corneaNormalW, 1.0f / IOR);
            half cosAlpha = dot(-viewRefrDirW, normalize(forwardDir));
            half distance = heightData / cosAlpha;
            half3 offsetW = viewRefrDirW * distance;
            offsetUV = mul(unity_WorldToObject, offsetW).xy;
        }

        void Unity_Multiply_float(float2 A, float2 B, out float2 Out)
        {
            Out = A * B;
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_Add_float2(float2 A, float2 B, out float2 Out)
        {
            Out = A + B;
        }

        void Unity_Negate_float3(float3 In, out float3 Out)
        {
            Out = -1 * In;
        }

        void CustomLight_float(float3 Albedo, float3 ViewDirection, float3 IrisWorldNormal, float Metallic, float Smoothness, float SpecularMask, out float3 FinalColor){
            half3 diffuseColor = Albedo * (1 - Metallic);
            half3 specularColor = Albedo * Metallic;
            half3 lightDir = normalize(_MainLightPosition.xyz);
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
            half FD90 = 0.5 + 2 * VdotH * VdotH * Roughness;
            half FdV = 1 + (FD90 - 1) * (1 - NdotV) * (1 - NdotV) * (1 - NdotV) * (1 - NdotV) * (1 - NdotV);
            half FdL = 1 + (FD90 - 1) * (1 - NdotL) * (1 - NdotL) * (1 - NdotL) * (1 - NdotL) * (1 - NdotL);
            half3 diffuse = diffuseColor * FdV * FdL;
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
            half3 specular = SpecularMask * D_GTR2 * F_Schlick * (saturate(G_GGX/(4 * NdotL * VdotH)));
            FinalColor = specular + diffuse;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float3 BaseColor;
            float3 NormalTS;
            float3 Emission;
            float Metallic;
            float Smoothness;
            float Occlusion;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            UnityTexture2D _Property_f2272dd4998b46269e54d957e7b8483e_Out_0 = UnityBuildTexture2DStructNoScale(_Albedo_RGB_);
            float4 _UV_f2ce5ad282824f3c9efacac42b9d35e1_Out_0 = IN.uv0;
            UnityTexture2D _Property_945106df349f4dc1af007b3053b22f1d_Out_0 = UnityBuildTexture2DStructNoScale(_CorneaNormalMap);
            float4 _SampleTexture2D_1df191bad2fc488985b3a30ba48d8224_RGBA_0 = SAMPLE_TEXTURE2D(_Property_945106df349f4dc1af007b3053b22f1d_Out_0.tex, _Property_945106df349f4dc1af007b3053b22f1d_Out_0.samplerstate, IN.uv0.xy);
            _SampleTexture2D_1df191bad2fc488985b3a30ba48d8224_RGBA_0.rgb = UnpackNormal(_SampleTexture2D_1df191bad2fc488985b3a30ba48d8224_RGBA_0);
            float _SampleTexture2D_1df191bad2fc488985b3a30ba48d8224_R_4 = _SampleTexture2D_1df191bad2fc488985b3a30ba48d8224_RGBA_0.r;
            float _SampleTexture2D_1df191bad2fc488985b3a30ba48d8224_G_5 = _SampleTexture2D_1df191bad2fc488985b3a30ba48d8224_RGBA_0.g;
            float _SampleTexture2D_1df191bad2fc488985b3a30ba48d8224_B_6 = _SampleTexture2D_1df191bad2fc488985b3a30ba48d8224_RGBA_0.b;
            float _SampleTexture2D_1df191bad2fc488985b3a30ba48d8224_A_7 = _SampleTexture2D_1df191bad2fc488985b3a30ba48d8224_RGBA_0.a;
            float3x3 Transform_81fd3c4d62b740dcad630ce63f9c8c5e_transposeTangent = transpose(float3x3(IN.WorldSpaceTangent, IN.WorldSpaceBiTangent, IN.WorldSpaceNormal));
            float3 _Transform_81fd3c4d62b740dcad630ce63f9c8c5e_Out_1 = normalize(mul(Transform_81fd3c4d62b740dcad630ce63f9c8c5e_transposeTangent, (_SampleTexture2D_1df191bad2fc488985b3a30ba48d8224_RGBA_0.xyz).xyz).xyz);
            float3 _Normalize_1eb23240f669476ca79425eedf8dc329_Out_1;
            Unity_Normalize_float3(_Transform_81fd3c4d62b740dcad630ce63f9c8c5e_Out_1, _Normalize_1eb23240f669476ca79425eedf8dc329_Out_1);
            float3 _Normalize_d83cd5e2983e4304acf00837d643a742_Out_1;
            Unity_Normalize_float3(IN.WorldSpaceViewDirection, _Normalize_d83cd5e2983e4304acf00837d643a742_Out_1);
            float3 _Vector3_bc75bd5c39614653948984506910d295_Out_0 = float3(0, 0, 1);
            float3 _Transform_5f432632021a4eb8969f6ccc45d88429_Out_1 = TransformObjectToWorldDir(_Vector3_bc75bd5c39614653948984506910d295_Out_0.xyz);
            float3 _Normalize_568ee998a3d542bfadc1c726618da559_Out_1;
            Unity_Normalize_float3(_Transform_5f432632021a4eb8969f6ccc45d88429_Out_1, _Normalize_568ee998a3d542bfadc1c726618da559_Out_1);
            UnityTexture2D _Property_5b57865f0e864fc1929a6314c10fe626_Out_0 = UnityBuildTexture2DStructNoScale(_CorneaMSO);
            float4 _SampleTexture2D_649d6832a8084d32b59612720f49c1e0_RGBA_0 = SAMPLE_TEXTURE2D(_Property_5b57865f0e864fc1929a6314c10fe626_Out_0.tex, _Property_5b57865f0e864fc1929a6314c10fe626_Out_0.samplerstate, IN.uv0.xy);
            float _SampleTexture2D_649d6832a8084d32b59612720f49c1e0_R_4 = _SampleTexture2D_649d6832a8084d32b59612720f49c1e0_RGBA_0.r;
            float _SampleTexture2D_649d6832a8084d32b59612720f49c1e0_G_5 = _SampleTexture2D_649d6832a8084d32b59612720f49c1e0_RGBA_0.g;
            float _SampleTexture2D_649d6832a8084d32b59612720f49c1e0_B_6 = _SampleTexture2D_649d6832a8084d32b59612720f49c1e0_RGBA_0.b;
            float _SampleTexture2D_649d6832a8084d32b59612720f49c1e0_A_7 = _SampleTexture2D_649d6832a8084d32b59612720f49c1e0_RGBA_0.a;
            float2 _UVOffsetCustomFunction_1cbea4bef08a48bbab888ac658ec6e57_offsetUV_1;
            float3 _UVOffsetCustomFunction_1cbea4bef08a48bbab888ac658ec6e57_viewRefrDirW_7;
            UVOffset_float(_Normalize_1eb23240f669476ca79425eedf8dc329_Out_1, _Normalize_d83cd5e2983e4304acf00837d643a742_Out_1, _Normalize_568ee998a3d542bfadc1c726618da559_Out_1, _SampleTexture2D_649d6832a8084d32b59612720f49c1e0_B_6, _UVOffsetCustomFunction_1cbea4bef08a48bbab888ac658ec6e57_offsetUV_1, _UVOffsetCustomFunction_1cbea4bef08a48bbab888ac658ec6e57_viewRefrDirW_7);
            float2 _Vector2_d49f235028434be6896b66ee08e5a431_Out_0 = float2(-1, 1);
            float2 _Multiply_046dc79e17e84106b267dcae69582837_Out_2;
            Unity_Multiply_float(_UVOffsetCustomFunction_1cbea4bef08a48bbab888ac658ec6e57_offsetUV_1, _Vector2_d49f235028434be6896b66ee08e5a431_Out_0, _Multiply_046dc79e17e84106b267dcae69582837_Out_2);
            float _Property_570aa07405a0410fac902bc9eff6d450_Out_0 = _HeightWeight;
            float _Multiply_945b3e8a74f64ae890dc81cdc73bb8f0_Out_2;
            Unity_Multiply_float(_SampleTexture2D_649d6832a8084d32b59612720f49c1e0_A_7, _Property_570aa07405a0410fac902bc9eff6d450_Out_0, _Multiply_945b3e8a74f64ae890dc81cdc73bb8f0_Out_2);
            float2 _Multiply_6b0c35d1b44540bba75ae35f2d9e334c_Out_2;
            Unity_Multiply_float(_Multiply_046dc79e17e84106b267dcae69582837_Out_2, (_Multiply_945b3e8a74f64ae890dc81cdc73bb8f0_Out_2.xx), _Multiply_6b0c35d1b44540bba75ae35f2d9e334c_Out_2);
            float2 _Add_281fecc0ca2a44aba05b736443af6639_Out_2;
            Unity_Add_float2((_UV_f2ce5ad282824f3c9efacac42b9d35e1_Out_0.xy), _Multiply_6b0c35d1b44540bba75ae35f2d9e334c_Out_2, _Add_281fecc0ca2a44aba05b736443af6639_Out_2);
            float4 _SampleTexture2D_4ba91cdca0684350b072d7e87298412f_RGBA_0 = SAMPLE_TEXTURE2D(_Property_f2272dd4998b46269e54d957e7b8483e_Out_0.tex, _Property_f2272dd4998b46269e54d957e7b8483e_Out_0.samplerstate, _Add_281fecc0ca2a44aba05b736443af6639_Out_2);
            float _SampleTexture2D_4ba91cdca0684350b072d7e87298412f_R_4 = _SampleTexture2D_4ba91cdca0684350b072d7e87298412f_RGBA_0.r;
            float _SampleTexture2D_4ba91cdca0684350b072d7e87298412f_G_5 = _SampleTexture2D_4ba91cdca0684350b072d7e87298412f_RGBA_0.g;
            float _SampleTexture2D_4ba91cdca0684350b072d7e87298412f_B_6 = _SampleTexture2D_4ba91cdca0684350b072d7e87298412f_RGBA_0.b;
            float _SampleTexture2D_4ba91cdca0684350b072d7e87298412f_A_7 = _SampleTexture2D_4ba91cdca0684350b072d7e87298412f_RGBA_0.a;
            float3 _Negate_ce3117a8d97c4c1f8212b0e54a18ea50_Out_1;
            Unity_Negate_float3(_UVOffsetCustomFunction_1cbea4bef08a48bbab888ac658ec6e57_viewRefrDirW_7, _Negate_ce3117a8d97c4c1f8212b0e54a18ea50_Out_1);
            UnityTexture2D _Property_046fbc8d106b4ee79400aa319a6bde0c_Out_0 = UnityBuildTexture2DStructNoScale(_IrisNormalMap);
            float4 _SampleTexture2D_792b1569ebda4cf0bc132763067454ad_RGBA_0 = SAMPLE_TEXTURE2D(_Property_046fbc8d106b4ee79400aa319a6bde0c_Out_0.tex, _Property_046fbc8d106b4ee79400aa319a6bde0c_Out_0.samplerstate, _Add_281fecc0ca2a44aba05b736443af6639_Out_2);
            _SampleTexture2D_792b1569ebda4cf0bc132763067454ad_RGBA_0.rgb = UnpackNormal(_SampleTexture2D_792b1569ebda4cf0bc132763067454ad_RGBA_0);
            float _SampleTexture2D_792b1569ebda4cf0bc132763067454ad_R_4 = _SampleTexture2D_792b1569ebda4cf0bc132763067454ad_RGBA_0.r;
            float _SampleTexture2D_792b1569ebda4cf0bc132763067454ad_G_5 = _SampleTexture2D_792b1569ebda4cf0bc132763067454ad_RGBA_0.g;
            float _SampleTexture2D_792b1569ebda4cf0bc132763067454ad_B_6 = _SampleTexture2D_792b1569ebda4cf0bc132763067454ad_RGBA_0.b;
            float _SampleTexture2D_792b1569ebda4cf0bc132763067454ad_A_7 = _SampleTexture2D_792b1569ebda4cf0bc132763067454ad_RGBA_0.a;
            float3x3 Transform_41871579e7634c1f966bf97f3b48c39c_transposeTangent = transpose(float3x3(IN.WorldSpaceTangent, IN.WorldSpaceBiTangent, IN.WorldSpaceNormal));
            float3 _Transform_41871579e7634c1f966bf97f3b48c39c_Out_1 = mul(Transform_41871579e7634c1f966bf97f3b48c39c_transposeTangent, (_SampleTexture2D_792b1569ebda4cf0bc132763067454ad_RGBA_0.xyz).xyz).xyz;
            UnityTexture2D _Property_32eb3ff548c74cf79bb1b0b0bd0cad19_Out_0 = UnityBuildTexture2DStructNoScale(_IrisMSO);
            float4 _SampleTexture2D_bef70bc2a771432cb911143fff476c4f_RGBA_0 = SAMPLE_TEXTURE2D(_Property_32eb3ff548c74cf79bb1b0b0bd0cad19_Out_0.tex, _Property_32eb3ff548c74cf79bb1b0b0bd0cad19_Out_0.samplerstate, _Add_281fecc0ca2a44aba05b736443af6639_Out_2);
            float _SampleTexture2D_bef70bc2a771432cb911143fff476c4f_R_4 = _SampleTexture2D_bef70bc2a771432cb911143fff476c4f_RGBA_0.r;
            float _SampleTexture2D_bef70bc2a771432cb911143fff476c4f_G_5 = _SampleTexture2D_bef70bc2a771432cb911143fff476c4f_RGBA_0.g;
            float _SampleTexture2D_bef70bc2a771432cb911143fff476c4f_B_6 = _SampleTexture2D_bef70bc2a771432cb911143fff476c4f_RGBA_0.b;
            float _SampleTexture2D_bef70bc2a771432cb911143fff476c4f_A_7 = _SampleTexture2D_bef70bc2a771432cb911143fff476c4f_RGBA_0.a;
            float _Property_19c6cce68ffb453782822b1c2bc861fa_Out_0 = _IrisMetallic;
            float _Multiply_570dfaa895634f2e837996a268d375ee_Out_2;
            Unity_Multiply_float(_SampleTexture2D_bef70bc2a771432cb911143fff476c4f_R_4, _Property_19c6cce68ffb453782822b1c2bc861fa_Out_0, _Multiply_570dfaa895634f2e837996a268d375ee_Out_2);
            float _Property_1f9893e43b854dc2b17d4ebecc5348e7_Out_0 = _IrisSmoothness;
            float _Multiply_32f96b612cc4403b990ddbe19baf2c02_Out_2;
            Unity_Multiply_float(_SampleTexture2D_bef70bc2a771432cb911143fff476c4f_G_5, _Property_1f9893e43b854dc2b17d4ebecc5348e7_Out_0, _Multiply_32f96b612cc4403b990ddbe19baf2c02_Out_2);
            float _Property_769fb7698e034178be9008a3e607c8f1_Out_0 = _IrisAOStrength;
            float _Multiply_8c2ecdb7fafe4f5d9667d4cd109d7bd4_Out_2;
            Unity_Multiply_float(_SampleTexture2D_bef70bc2a771432cb911143fff476c4f_B_6, _Property_769fb7698e034178be9008a3e607c8f1_Out_0, _Multiply_8c2ecdb7fafe4f5d9667d4cd109d7bd4_Out_2);
            float3 _CustomLightCustomFunction_068f9cb549e342bda035c1b2b3ba0676_FinalColor_0;
            CustomLight_float((_SampleTexture2D_4ba91cdca0684350b072d7e87298412f_RGBA_0.xyz), _Negate_ce3117a8d97c4c1f8212b0e54a18ea50_Out_1, _Transform_41871579e7634c1f966bf97f3b48c39c_Out_1, _Multiply_570dfaa895634f2e837996a268d375ee_Out_2, _Multiply_32f96b612cc4403b990ddbe19baf2c02_Out_2, _Multiply_8c2ecdb7fafe4f5d9667d4cd109d7bd4_Out_2, _CustomLightCustomFunction_068f9cb549e342bda035c1b2b3ba0676_FinalColor_0);
            float _Property_b33ce5a648714f609015b60d88056592_Out_0 = _CorneaMetallic;
            float _Multiply_21523663351549588bbfcc46f5a9dc84_Out_2;
            Unity_Multiply_float(_SampleTexture2D_649d6832a8084d32b59612720f49c1e0_R_4, _Property_b33ce5a648714f609015b60d88056592_Out_0, _Multiply_21523663351549588bbfcc46f5a9dc84_Out_2);
            float _Property_5068534489bb419d9daa71fcb4e08755_Out_0 = _CorneaSmoothness;
            float _Multiply_65a14cb177fc46abb116eb0bcd71eb9a_Out_2;
            Unity_Multiply_float(_SampleTexture2D_649d6832a8084d32b59612720f49c1e0_G_5, _Property_5068534489bb419d9daa71fcb4e08755_Out_0, _Multiply_65a14cb177fc46abb116eb0bcd71eb9a_Out_2);
            surface.BaseColor = _CustomLightCustomFunction_068f9cb549e342bda035c1b2b3ba0676_FinalColor_0;
            surface.NormalTS = (_SampleTexture2D_1df191bad2fc488985b3a30ba48d8224_RGBA_0.xyz);
            surface.Emission = float3(0, 0, 0);
            surface.Metallic = _Multiply_21523663351549588bbfcc46f5a9dc84_Out_2;
            surface.Smoothness = _Multiply_65a14cb177fc46abb116eb0bcd71eb9a_Out_2;
            surface.Occlusion = 1;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

        	// must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
        	float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);

        	// use bitangent on the fly like in hdrp
        	// IMPORTANT! If we ever support Flip on double sided materials ensure bitangent and tangent are NOT flipped.
            float crossSign = (input.tangentWS.w > 0.0 ? 1.0 : -1.0) * GetOddNegativeScale();
        	float3 bitang = crossSign * cross(input.normalWS.xyz, input.tangentWS.xyz);

            output.WorldSpaceNormal =            renormFactor*input.normalWS.xyz;		// we want a unit length Normal Vector node in shader graph
            output.ObjectSpaceNormal =           normalize(mul(output.WorldSpaceNormal, (float3x3) UNITY_MATRIX_M));           // transposed multiplication by inverse matrix to handle normal scale
            output.TangentSpaceNormal =          float3(0.0f, 0.0f, 1.0f);

        	// to preserve mikktspace compliance we use same scale renormFactor as was used on the normal.
        	// This is explained in section 2.2 in "surface gradient based bump mapping framework"
            output.WorldSpaceTangent =           renormFactor*input.tangentWS.xyz;
        	output.WorldSpaceBiTangent =         renormFactor*bitang;

            output.ObjectSpaceTangent =          TransformWorldToObjectDir(output.WorldSpaceTangent);
            output.ObjectSpaceBiTangent =        TransformWorldToObjectDir(output.WorldSpaceBiTangent);
            output.WorldSpaceViewDirection =     input.viewDirectionWS; //TODO: by default normalized in HD, but not in universal
            output.uv0 =                         input.texCoord0;
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBRForwardPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }

            // Render State
            Cull Back
        Blend One Zero
        ZTest LEqual
        ZWrite On
        ColorMask 0

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            // PassKeywords: <None>
            // GraphKeywords: <None>

            // Defines
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_SHADOWCASTER
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float4 _Albedo_RGB__TexelSize;
        float4 _CorneaNormalMap_TexelSize;
        float4 _CorneaMSO_TexelSize;
        float _CorneaMetallic;
        float _CorneaSmoothness;
        float _HeightWeight;
        float4 _IrisNormalMap_TexelSize;
        float4 _IrisMSO_TexelSize;
        float _IrisMetallic;
        float _IrisSmoothness;
        float _IrisAOStrength;
        CBUFFER_END

        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_Albedo_RGB_);
        SAMPLER(sampler_Albedo_RGB_);
        TEXTURE2D(_CorneaNormalMap);
        SAMPLER(sampler_CorneaNormalMap);
        TEXTURE2D(_CorneaMSO);
        SAMPLER(sampler_CorneaMSO);
        TEXTURE2D(_IrisNormalMap);
        SAMPLER(sampler_IrisNormalMap);
        TEXTURE2D(_IrisMSO);
        SAMPLER(sampler_IrisMSO);

            // Graph Functions
            // GraphFunctions: <None>

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);





        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShadowCasterPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }

            // Render State
            Cull Back
        Blend One Zero
        ZTest LEqual
        ZWrite On
        ColorMask 0

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            // PassKeywords: <None>
            // GraphKeywords: <None>

            // Defines
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_DEPTHONLY
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float4 _Albedo_RGB__TexelSize;
        float4 _CorneaNormalMap_TexelSize;
        float4 _CorneaMSO_TexelSize;
        float _CorneaMetallic;
        float _CorneaSmoothness;
        float _HeightWeight;
        float4 _IrisNormalMap_TexelSize;
        float4 _IrisMSO_TexelSize;
        float _IrisMetallic;
        float _IrisSmoothness;
        float _IrisAOStrength;
        CBUFFER_END

        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_Albedo_RGB_);
        SAMPLER(sampler_Albedo_RGB_);
        TEXTURE2D(_CorneaNormalMap);
        SAMPLER(sampler_CorneaNormalMap);
        TEXTURE2D(_CorneaMSO);
        SAMPLER(sampler_CorneaMSO);
        TEXTURE2D(_IrisNormalMap);
        SAMPLER(sampler_IrisNormalMap);
        TEXTURE2D(_IrisMSO);
        SAMPLER(sampler_IrisMSO);

            // Graph Functions
            // GraphFunctions: <None>

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);





        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthOnlyPass.hlsl"

            ENDHLSL
        }
    }
    CustomEditor "ShaderGraph.PBRMasterGUI"
    FallBack "Hidden/Shader Graph/FallbackError"
}