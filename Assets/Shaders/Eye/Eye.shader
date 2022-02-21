// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Eye"
{
	Properties
	{
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		[ASEBegin]_AlbedoRGB("Albedo (RGB)", 2D) = "white" {}
		_DiffuseColorStrength("DiffuseColorStrength", Range( 0 , 3.14159)) = 1
		_CorneaNormal("CorneaNormal", 2D) = "bump" {}
		_CorneaNormalStrength("CorneaNormalStrength", Range( 0 , 2)) = 1
		_IrisNormal("IrisNormal", 2D) = "bump" {}
		_IrisNormalStrength("IrisNormalStrength", Range( 0 , 2)) = 1
		_IrisSpecularMask("IrisSpecularMask", 2D) = "white" {}
		_IrisMask("IrisMask", 2D) = "white" {}
		_MetallicTex("MetallicTex", 2D) = "white" {}
		_Metallic("Metallic", Range( 0 , 1)) = 1
		_RoughnessTex("RoughnessTex", 2D) = "white" {}
		_Roughness("Roughness", Range( 0 , 1)) = 1
		_HeightMap("HeightMap", 2D) = "white" {}
		_HeightWeight("HeightWeight", Range( 0 , 1)) = 0
		_EnvCubemap("EnvCubemap", CUBE) = "white" {}
		_CorneaRoughness("CorneaRoughness", Range( 0.01 , 1)) = 0.1982353
		[ASEEnd]_CorneaF0("CorneaF0", Range( 0.025 , 1)) = 0.1982353
		[HideInInspector] _texcoord( "", 2D ) = "white" {}

		//_TessPhongStrength( "Tess Phong Strength", Range( 0, 1 ) ) = 0.5
		//_TessValue( "Tess Max Tessellation", Range( 1, 32 ) ) = 16
		//_TessMin( "Tess Min Distance", Float ) = 10
		//_TessMax( "Tess Max Distance", Float ) = 25
		//_TessEdgeLength ( "Tess Edge length", Range( 2, 50 ) ) = 16
		//_TessMaxDisp( "Tess Max Displacement", Float ) = 25
	}

	SubShader
	{
		LOD 0

		
		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry" }
		
		Cull Back
		AlphaToMask Off
		HLSLINCLUDE
		#pragma target 2.0

		#ifndef ASE_TESS_FUNCS
		#define ASE_TESS_FUNCS
		float4 FixedTess( float tessValue )
		{
			return tessValue;
		}
		
		float CalcDistanceTessFactor (float4 vertex, float minDist, float maxDist, float tess, float4x4 o2w, float3 cameraPos )
		{
			float3 wpos = mul(o2w,vertex).xyz;
			float dist = distance (wpos, cameraPos);
			float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tess;
			return f;
		}

		float4 CalcTriEdgeTessFactors (float3 triVertexFactors)
		{
			float4 tess;
			tess.x = 0.5 * (triVertexFactors.y + triVertexFactors.z);
			tess.y = 0.5 * (triVertexFactors.x + triVertexFactors.z);
			tess.z = 0.5 * (triVertexFactors.x + triVertexFactors.y);
			tess.w = (triVertexFactors.x + triVertexFactors.y + triVertexFactors.z) / 3.0f;
			return tess;
		}

		float CalcEdgeTessFactor (float3 wpos0, float3 wpos1, float edgeLen, float3 cameraPos, float4 scParams )
		{
			float dist = distance (0.5 * (wpos0+wpos1), cameraPos);
			float len = distance(wpos0, wpos1);
			float f = max(len * scParams.y / (edgeLen * dist), 1.0);
			return f;
		}

		float DistanceFromPlane (float3 pos, float4 plane)
		{
			float d = dot (float4(pos,1.0f), plane);
			return d;
		}

		bool WorldViewFrustumCull (float3 wpos0, float3 wpos1, float3 wpos2, float cullEps, float4 planes[6] )
		{
			float4 planeTest;
			planeTest.x = (( DistanceFromPlane(wpos0, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[0]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.y = (( DistanceFromPlane(wpos0, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[1]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.z = (( DistanceFromPlane(wpos0, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[2]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.w = (( DistanceFromPlane(wpos0, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[3]) > -cullEps) ? 1.0f : 0.0f );
			return !all (planeTest);
		}

		float4 DistanceBasedTess( float4 v0, float4 v1, float4 v2, float tess, float minDist, float maxDist, float4x4 o2w, float3 cameraPos )
		{
			float3 f;
			f.x = CalcDistanceTessFactor (v0,minDist,maxDist,tess,o2w,cameraPos);
			f.y = CalcDistanceTessFactor (v1,minDist,maxDist,tess,o2w,cameraPos);
			f.z = CalcDistanceTessFactor (v2,minDist,maxDist,tess,o2w,cameraPos);

			return CalcTriEdgeTessFactors (f);
		}

		float4 EdgeLengthBasedTess( float4 v0, float4 v1, float4 v2, float edgeLength, float4x4 o2w, float3 cameraPos, float4 scParams )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;
			tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
			tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
			tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
			tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			return tess;
		}

		float4 EdgeLengthBasedTessCull( float4 v0, float4 v1, float4 v2, float edgeLength, float maxDisplacement, float4x4 o2w, float3 cameraPos, float4 scParams, float4 planes[6] )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;

			if (WorldViewFrustumCull(pos0, pos1, pos2, maxDisplacement, planes))
			{
				tess = 0.0f;
			}
			else
			{
				tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
				tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
				tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
				tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			}
			return tess;
		}
		#endif //ASE_TESS_FUNCS

		ENDHLSL

		
		Pass
		{
			
			Name "Forward"
			Tags { "LightMode"="UniversalForward" }
			
			Blend One Zero, One Zero
			ZWrite On
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA
			

			HLSLPROGRAM
			#pragma multi_compile_instancing
			#define ASE_SRP_VERSION 999999

			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x

			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

			#if ASE_SRP_VERSION <= 70108
			#define REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR
			#endif

			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#define ASE_NEEDS_VERT_NORMAL


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_tangent : TANGENT;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD1;
				#endif
				#ifdef ASE_FOG
				float fogFactor : TEXCOORD2;
				#endif
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord4 : TEXCOORD4;
				float4 ase_texcoord5 : TEXCOORD5;
				float4 ase_texcoord6 : TEXCOORD6;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _IrisMask_ST;
			float4 _HeightMap_ST;
			float4 _CorneaNormal_ST;
			float _HeightWeight;
			float _CorneaNormalStrength;
			float _Metallic;
			float _Roughness;
			float _IrisNormalStrength;
			float _DiffuseColorStrength;
			float _CorneaRoughness;
			float _CorneaF0;
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			sampler2D _AlbedoRGB;
			sampler2D _IrisMask;
			sampler2D _HeightMap;
			sampler2D _CorneaNormal;
			sampler2D _MetallicTex;
			sampler2D _RoughnessTex;
			sampler2D _IrisNormal;
			sampler2D _IrisSpecularMask;
			samplerCUBE _EnvCubemap;


			float3 DisneyDiffuse85( float3 DiffuseColor, float Roughness, float NdotV, float NdotL, float LdotH )
			{
				float FD90 = 0.5 + 2 * LdotH * LdotH * Roughness;
				float FdV = 1 + (FD90 - 1) * (1 - NdotV) * (1 - NdotV) * (1 - NdotV) * (1 - NdotV) * (1 - NdotV);
				float FdL = 1 + (FD90 - 1) * (1 - NdotL) * (1 - NdotL) * (1 - NdotL) * (1 - NdotL) * (1 - NdotL);
				return DiffuseColor * ((1.0 / 3.14159265) * FdV * FdL);
			}
			
			float D_GTR21_g17( float Roughness, float NdotH )
			{
				float a2 = Roughness * Roughness;
				float cos2th = NdotH * NdotH;
				float den = (1.0 + (a2 - 1.0) * cos2th);
				return a2 / (3.14159265 * den * den);
			}
			
			float3 F_Schlick2_g17( float3 F0, float VdotH )
			{
				 return F0 + (1 - F0) * (1 - VdotH) * (1 - VdotH)  * (1 - VdotH)  * (1 - VdotH)  * (1 - VdotH);
			}
			
			float G_GGX3_g17( float Roughness, float NdotV )
			{
				float alphaG = (0.5 + Roughness / 2) * (0.5 + Roughness / 2);
				float a2 = alphaG * alphaG;
				float b2 = NdotV * NdotV;
				return 1 / (NdotV + sqrt(a2 + b2 - a2 * b2));
			}
			
			float D_GTR21_g18( float Roughness, float NdotH )
			{
				float a2 = Roughness * Roughness;
				float cos2th = NdotH * NdotH;
				float den = (1.0 + (a2 - 1.0) * cos2th);
				return a2 / (3.14159265 * den * den);
			}
			
			float3 F_Schlick2_g18( float3 F0, float VdotH )
			{
				 return F0 + (1 - F0) * (1 - VdotH) * (1 - VdotH)  * (1 - VdotH)  * (1 - VdotH)  * (1 - VdotH);
			}
			
			float G_GGX3_g18( float Roughness, float NdotV )
			{
				float alphaG = (0.5 + Roughness / 2) * (0.5 + Roughness / 2);
				float a2 = alphaG * alphaG;
				float b2 = NdotV * NdotV;
				return 1 / (NdotV + sqrt(a2 + b2 - a2 * b2));
			}
			
			
			VertexOutput VertexFunction ( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 ase_worldTangent = TransformObjectToWorldDir(v.ase_tangent.xyz);
				o.ase_texcoord4.xyz = ase_worldTangent;
				float3 ase_worldNormal = TransformObjectToWorldNormal(v.ase_normal);
				o.ase_texcoord5.xyz = ase_worldNormal;
				float ase_vertexTangentSign = v.ase_tangent.w * unity_WorldTransformParams.w;
				float3 ase_worldBitangent = cross( ase_worldNormal, ase_worldTangent ) * ase_vertexTangentSign;
				o.ase_texcoord6.xyz = ase_worldBitangent;
				
				o.ase_texcoord3.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord3.zw = 0;
				o.ase_texcoord4.w = 0;
				o.ase_texcoord5.w = 0;
				o.ase_texcoord6.w = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = defaultVertexValue;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif
				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float4 positionCS = TransformWorldToHClip( positionWS );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				o.worldPos = positionWS;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				VertexPositionInputs vertexInput = (VertexPositionInputs)0;
				vertexInput.positionWS = positionWS;
				vertexInput.positionCS = positionCS;
				o.shadowCoord = GetShadowCoord( vertexInput );
				#endif
				#ifdef ASE_FOG
				o.fogFactor = ComputeFogFactor( positionCS.z );
				#endif
				o.clipPos = positionCS;
				return o;
			}

			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_tangent : TANGENT;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_texcoord = v.ase_texcoord;
				o.ase_tangent = v.ase_tangent;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_tangent = patch[0].ase_tangent * bary.x + patch[1].ase_tangent * bary.y + patch[2].ase_tangent * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag ( VertexOutput IN  ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 WorldPosition = IN.worldPos;
				#endif
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif
				float2 texCoord55 = IN.ase_texcoord3.xy * float2( 1,1 ) + float2( 0,0 );
				float2 uv_IrisMask = IN.ase_texcoord3.xy * _IrisMask_ST.xy + _IrisMask_ST.zw;
				float2 uv_HeightMap = IN.ase_texcoord3.xy * _HeightMap_ST.xy + _HeightMap_ST.zw;
				float3 ase_worldViewDir = ( _WorldSpaceCameraPos.xyz - WorldPosition );
				ase_worldViewDir = SafeNormalize( ase_worldViewDir );
				float2 uv_CorneaNormal = IN.ase_texcoord3.xy * _CorneaNormal_ST.xy + _CorneaNormal_ST.zw;
				float3 unpack22 = UnpackNormalScale( tex2D( _CorneaNormal, uv_CorneaNormal ), _CorneaNormalStrength );
				unpack22.z = lerp( 1, unpack22.z, saturate(_CorneaNormalStrength) );
				float3 ase_worldTangent = IN.ase_texcoord4.xyz;
				float3 ase_worldNormal = IN.ase_texcoord5.xyz;
				float3 ase_worldBitangent = IN.ase_texcoord6.xyz;
				float3x3 ase_tangentToWorldFast = float3x3(ase_worldTangent.x,ase_worldBitangent.x,ase_worldNormal.x,ase_worldTangent.y,ase_worldBitangent.y,ase_worldNormal.y,ase_worldTangent.z,ase_worldBitangent.z,ase_worldNormal.z);
				float3 tangentToWorldDir23 = normalize( mul( ase_tangentToWorldFast, unpack22 ) );
				float3 temp_output_25_0 = refract( -ase_worldViewDir , tangentToWorldDir23 , 0.751879 );
				float3 objToWorldDir29 = normalize( mul( GetObjectToWorldMatrix(), float4( float3(0,0,1), 0 ) ).xyz );
				float dotResult31 = dot( -temp_output_25_0 , objToWorldDir29 );
				float3 worldToObjDir37 = mul( GetWorldToObjectMatrix(), float4( ( ( tex2D( _HeightMap, uv_HeightMap ).r / dotResult31 ) * temp_output_25_0 ), 0 ) ).xyz;
				float2 appendResult38 = (float2(worldToObjDir37.x , worldToObjDir37.y));
				float2 UVOffset42 = ( texCoord55 + ( tex2D( _IrisMask, uv_IrisMask ).r * _HeightWeight * float2( -1,1 ) * appendResult38 ) );
				float4 tex2DNode72 = tex2D( _AlbedoRGB, UVOffset42 );
				float temp_output_46_0 = max( ( tex2D( _MetallicTex, UVOffset42 ).r * _Metallic ) , 0.04 );
				float4 DiffuseColor82 = ( tex2DNode72 * ( 1.0 - temp_output_46_0 ) );
				float3 DiffuseColor85 = DiffuseColor82.rgb;
				float RoughnessValue53 = ( tex2D( _RoughnessTex, UVOffset42 ).r * _Roughness );
				float Roughness85 = RoughnessValue53;
				float3 unpack77 = UnpackNormalScale( tex2D( _IrisNormal, UVOffset42 ), _IrisNormalStrength );
				unpack77.z = lerp( 1, unpack77.z, saturate(_IrisNormalStrength) );
				float3 tangentToWorldDir78 = normalize( mul( ase_tangentToWorldFast, unpack77 ) );
				float3 RefractViewDir89 = -temp_output_25_0;
				float dotResult91 = dot( tangentToWorldDir78 , RefractViewDir89 );
				float IrisNdotV92 = saturate( dotResult91 );
				float NdotV85 = IrisNdotV92;
				float dotResult93 = dot( tangentToWorldDir78 , _MainLightPosition.xyz );
				float IrisNdotL95 = saturate( dotResult93 );
				float NdotL85 = IrisNdotL95;
				float3 normalizeResult98 = normalize( ( RefractViewDir89 + _MainLightPosition.xyz ) );
				float3 IrisHalfDir97 = normalizeResult98;
				float dotResult99 = dot( _MainLightPosition.xyz , IrisHalfDir97 );
				float IrisLdotH102 = saturate( dotResult99 );
				float LdotH85 = IrisLdotH102;
				float3 localDisneyDiffuse85 = DisneyDiffuse85( DiffuseColor85 , Roughness85 , NdotV85 , NdotL85 , LdotH85 );
				float3 DisneyDiffuseColor108 = ( localDisneyDiffuse85 * _MainLightColor.rgb );
				float temp_output_8_0_g17 = RoughnessValue53;
				float Roughness1_g17 = temp_output_8_0_g17;
				float dotResult131 = dot( tangentToWorldDir78 , IrisHalfDir97 );
				float IrisNdotH135 = saturate( dotResult131 );
				float NdotH1_g17 = IrisNdotH135;
				float localD_GTR21_g17 = D_GTR21_g17( Roughness1_g17 , NdotH1_g17 );
				float4 SpecularColor80 = ( tex2DNode72 * temp_output_46_0 );
				float3 F02_g17 = SpecularColor80.rgb;
				float dotResult142 = dot( RefractViewDir89 , IrisHalfDir97 );
				float IrisVdotH143 = saturate( dotResult142 );
				float temp_output_12_0_g17 = IrisVdotH143;
				float VdotH2_g17 = temp_output_12_0_g17;
				float3 localF_Schlick2_g17 = F_Schlick2_g17( F02_g17 , VdotH2_g17 );
				float Roughness3_g17 = temp_output_8_0_g17;
				float NdotV3_g17 = IrisNdotV92;
				float localG_GGX3_g17 = G_GGX3_g17( Roughness3_g17 , NdotV3_g17 );
				float IrisSpecularMask62 = tex2D( _IrisSpecularMask, UVOffset42 ).r;
				float3 GGXSpecularColorIris153 = ( ( localD_GTR21_g17 * localF_Schlick2_g17 * saturate( ( localG_GGX3_g17 / ( 4.0 * temp_output_12_0_g17 * IrisNdotL95 ) ) ) ) * IrisSpecularMask62 );
				float3 IrisReflectDir66 = reflect( -ase_worldViewDir , tangentToWorldDir78 );
				float4 IndirectSpecularIris70 = ( texCUBElod( _EnvCubemap, float4( IrisReflectDir66, ( RoughnessValue53 * 6.0 )) ) * SpecularColor80 );
				float CorneaRoughness195 = _CorneaRoughness;
				float temp_output_8_0_g18 = CorneaRoughness195;
				float Roughness1_g18 = temp_output_8_0_g18;
				float3 CorneaWorldNormal168 = tangentToWorldDir23;
				ase_worldViewDir = normalize(ase_worldViewDir);
				float3 normalizeResult176 = normalize( ( _MainLightPosition.xyz + ase_worldViewDir ) );
				float dotResult179 = dot( CorneaWorldNormal168 , normalizeResult176 );
				float NdotH1_g18 = saturate( dotResult179 );
				float localD_GTR21_g18 = D_GTR21_g18( Roughness1_g18 , NdotH1_g18 );
				float CorneaF0196 = _CorneaF0;
				float3 temp_cast_6 = (CorneaF0196).xxx;
				float3 F02_g18 = temp_cast_6;
				float dotResult183 = dot( normalizeResult176 , ase_worldViewDir );
				float temp_output_12_0_g18 = saturate( dotResult183 );
				float VdotH2_g18 = temp_output_12_0_g18;
				float3 localF_Schlick2_g18 = F_Schlick2_g18( F02_g18 , VdotH2_g18 );
				float Roughness3_g18 = temp_output_8_0_g18;
				float dotResult181 = dot( CorneaWorldNormal168 , ase_worldViewDir );
				float NdotV3_g18 = saturate( dotResult181 );
				float localG_GGX3_g18 = G_GGX3_g18( Roughness3_g18 , NdotV3_g18 );
				float dotResult185 = dot( CorneaWorldNormal168 , _MainLightPosition.xyz );
				float3 GGXSpecularColorCornea190 = ( localD_GTR21_g18 * localF_Schlick2_g18 * saturate( ( localG_GGX3_g18 / ( 4.0 * temp_output_12_0_g18 * saturate( dotResult185 ) ) ) ) );
				float3 CorneaReflectDir202 = reflect( -ase_worldViewDir , tangentToWorldDir23 );
				float3 Fresnel224 = localF_Schlick2_g18;
				float4 IndirectSpecularCornea206 = ( texCUBElod( _EnvCubemap, float4( CorneaReflectDir202, ( 6.0 * CorneaRoughness195 )) ) * CorneaF0196 * float4( Fresnel224 , 0.0 ) );
				
				float3 BakedAlbedo = 0;
				float3 BakedEmission = 0;
				float3 Color = ( float4( ( DisneyDiffuseColor108 * _DiffuseColorStrength ) , 0.0 ) + float4( GGXSpecularColorIris153 , 0.0 ) + IndirectSpecularIris70 + float4( GGXSpecularColorCornea190 , 0.0 ) + IndirectSpecularCornea206 ).rgb;
				float Alpha = 1;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;

				#ifdef _ALPHATEST_ON
					clip( Alpha - AlphaClipThreshold );
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif

				#ifdef ASE_FOG
					Color = MixFog( Color, IN.fogFactor );
				#endif

				return half4( Color, Alpha );
			}

			ENDHLSL
		}

		
		Pass
		{
			
			Name "ShadowCaster"
			Tags { "LightMode"="ShadowCaster" }

			ZWrite On
			ZTest LEqual
			AlphaToMask Off

			HLSLPROGRAM
			#pragma multi_compile_instancing
			#define ASE_SRP_VERSION 999999

			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x

			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD1;
				#endif
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _IrisMask_ST;
			float4 _HeightMap_ST;
			float4 _CorneaNormal_ST;
			float _HeightWeight;
			float _CorneaNormalStrength;
			float _Metallic;
			float _Roughness;
			float _IrisNormalStrength;
			float _DiffuseColorStrength;
			float _CorneaRoughness;
			float _CorneaF0;
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			

			
			float3 _LightDirection;

			VertexOutput VertexFunction( VertexInput v )
			{
				VertexOutput o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );

				
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = defaultVertexValue;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				o.worldPos = positionWS;
				#endif

				float3 normalWS = TransformObjectToWorldDir( v.ase_normal );

				float4 clipPos = TransformWorldToHClip( ApplyShadowBias( positionWS, normalWS, _LightDirection ) );

				#if UNITY_REVERSED_Z
					clipPos.z = min(clipPos.z, clipPos.w * UNITY_NEAR_CLIP_VALUE);
				#else
					clipPos.z = max(clipPos.z, clipPos.w * UNITY_NEAR_CLIP_VALUE);
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = clipPos;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif
				o.clipPos = clipPos;

				return o;
			}
			
			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN  ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 WorldPosition = IN.worldPos;
				#endif
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				
				float Alpha = 1;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;

				#ifdef _ALPHATEST_ON
					#ifdef _ALPHATEST_SHADOW_ON
						clip(Alpha - AlphaClipThresholdShadow);
					#else
						clip(Alpha - AlphaClipThreshold);
					#endif
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif
				return 0;
			}

			ENDHLSL
		}

		
		Pass
		{
			
			Name "DepthOnly"
			Tags { "LightMode"="DepthOnly" }

			ZWrite On
			ColorMask 0
			AlphaToMask Off

			HLSLPROGRAM
			#pragma multi_compile_instancing
			#define ASE_SRP_VERSION 999999

			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x

			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD1;
				#endif
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _IrisMask_ST;
			float4 _HeightMap_ST;
			float4 _CorneaNormal_ST;
			float _HeightWeight;
			float _CorneaNormalStrength;
			float _Metallic;
			float _Roughness;
			float _IrisNormalStrength;
			float _DiffuseColorStrength;
			float _CorneaRoughness;
			float _CorneaF0;
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			

			
			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = defaultVertexValue;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				o.worldPos = positionWS;
				#endif

				o.clipPos = TransformWorldToHClip( positionWS );
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = clipPos;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif
				return o;
			}

			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN  ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 WorldPosition = IN.worldPos;
				#endif
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				
				float Alpha = 1;
				float AlphaClipThreshold = 0.5;

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif
				return 0;
			}
			ENDHLSL
		}

	
	}
	CustomEditor "UnityEditor.ShaderGraph.PBRMasterGUI"
	Fallback "Hidden/InternalErrorShader"
	
}
/*ASEBEGIN
Version=18900
-1941.6;64;2048;1064.6;1910.453;77.44003;1;True;True
Node;AmplifyShaderEditor.CommentaryNode;44;-4309.393,-854.1877;Inherit;False;2481.913;672.2053;UVOffset;37;22;24;25;27;21;9;7;26;23;16;32;36;35;34;37;38;39;17;33;13;40;41;30;31;29;28;55;56;42;65;66;89;165;166;168;201;202;;0.6015253,0.9622642,0.5755429,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;161;-3822.949,1148.244;Inherit;False;1136.718;842.3453;Indirect Specular;16;67;69;18;64;111;70;68;112;194;199;203;205;206;210;204;225;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;160;-2649.325,319.6647;Inherit;False;1082.259;539.4512;GGXIris;10;153;212;213;147;150;145;144;137;136;222;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;159;-2649.259,-159.9836;Inherit;False;982.8049;474.4213;DisneyColor;9;108;271;270;105;87;85;86;104;103;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;63;-4309.804,-159.8883;Inherit;False;1626.802;1286.502;MSS;48;19;61;62;51;20;12;53;45;15;46;49;47;14;52;72;5;59;78;77;10;76;8;79;80;81;82;91;92;93;94;95;96;97;98;99;102;106;113;114;119;131;133;134;135;140;141;142;143;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;189;-2645.473,884.2323;Inherit;False;1539.461;722.1774;GGXCornea;20;179;185;181;182;183;184;180;186;170;171;173;172;176;175;174;190;195;196;224;223;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;19;-3819.436,839.5507;Inherit;False;Property;_Roughness;Roughness;11;0;Create;True;0;0;0;False;0;False;1;0.112;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.UnpackScaleNormalNode;77;-3719.003,-56.26883;Inherit;False;2;0;FLOAT4;0,0,0,0;False;1;FLOAT;1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DotProductOpNode;131;-3206.632,243.5798;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;108;-1919.254,96.1923;Inherit;False;DisneyDiffuseColor;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;171;-2350.156,1011.743;Inherit;False;Property;_CorneaF0;CorneaF0;16;0;Create;True;0;0;0;False;0;False;0.1982353;0.3;0.025;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;97;-2929.137,49.0071;Inherit;False;IrisHalfDir;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TexturePropertyNode;14;-4084.459,366.9911;Inherit;True;Property;_MetallicTex;MetallicTex;8;0;Create;True;0;0;0;False;0;False;None;6d2b0bf80d3abc34792d973830dc94d0;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.RangedFloatNode;10;-4018.521,86.21926;Inherit;False;Property;_IrisNormalStrength;IrisNormalStrength;5;0;Create;True;0;0;0;False;0;False;1;1;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;55;-2212.334,-743.4296;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WireNode;140;-3464.715,481.6042;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.DotProductOpNode;181;-2054.518,1279.846;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;173;-2595.473,1180.233;Inherit;False;False;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.Vector3Node;28;-3650.887,-368.2394;Inherit;False;Constant;_ForwardDir;ForwardDir;14;0;Create;True;0;0;0;False;0;False;0,0,1;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleDivideOpNode;33;-2770.329,-615.7933;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;39;-2418.016,-516.6365;Inherit;False;Constant;_Invert;Invert;14;0;Create;True;0;0;0;False;0;False;-1,1;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.DotProductOpNode;142;-3204.277,337.3434;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;165;-1881.212,-617.6345;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.WireNode;36;-2809.779,-440.4918;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NormalizeNode;98;-3080.154,54.4985;Inherit;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;24;-3706.851,-726.036;Inherit;False;World;True;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WireNode;139;-3470.098,400.9392;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;42;-2018.28,-482.6698;Inherit;False;UVOffset;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;46;-3356.152,485.6545;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0.04;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;5;-4084.187,166.4837;Inherit;True;Property;_AlbedoRGB;Albedo (RGB);0;0;Create;True;0;0;0;False;0;False;None;3f62383b22e35bc45a944d522cd46544;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.RefractOpVec;25;-3242.965,-604.7817;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;134;-3474.345,313.0574;Inherit;False;97;IrisHalfDir;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;170;-2350.156,931.7418;Inherit;False;Property;_CorneaRoughness;CorneaRoughness;15;0;Create;True;0;0;0;False;0;False;0.1982353;0.03;0.01;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.TransformDirectionNode;29;-3502.198,-367.5824;Inherit;False;Object;World;True;Fast;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DynamicAppendNode;38;-2397.96,-388.3873;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DotProductOpNode;93;-3217.44,-34.58491;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;53;-3368.827,686.4919;Inherit;False;RoughnessValue;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;89;-2688.38,-499.3394;Inherit;False;RefractViewDir;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;174;-2570.473,1395.233;Inherit;False;World;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RegisterLocalVarNode;168;-3153.534,-486.8181;Inherit;False;CorneaWorldNormal;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DotProductOpNode;185;-2060.318,1089.845;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;172;-2434.172,1088.734;Inherit;False;168;CorneaWorldNormal;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;76;-4034.547,-110.1055;Inherit;True;Property;_TextureSample8;Texture Sample 8;14;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;17;-2540.654,-597.1956;Inherit;False;Property;_HeightWeight;HeightWeight;13;0;Create;True;0;0;0;False;0;False;0;0.08;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.TransformDirectionNode;78;-3505.152,-60.75521;Inherit;False;Tangent;World;True;Fast;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;94;-3512.415,169.9488;Inherit;False;False;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RegisterLocalVarNode;153;-1870.422,534.516;Inherit;False;GGXSpecularColorIris;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;32;-3101.06,-801.5978;Inherit;True;Property;_TextureSample1;Texture Sample 1;14;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TransformDirectionNode;37;-2623.951,-416.4694;Inherit;False;World;Object;False;Fast;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DotProductOpNode;91;-3219.56,-123.9226;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;70;-2918.836,1433.164;Inherit;False;IndirectSpecularIris;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;110;-1179.637,387.526;Inherit;False;70;IndirectSpecularIris;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;47;-3509.403,486.0335;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;72;-3838.464,179.8307;Inherit;True;Property;_TextureSample7;Texture Sample 7;14;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;95;-2944.765,-40.07638;Inherit;False;IrisNdotL;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;16;-3324.932,-803.0004;Inherit;True;Property;_HeightMap;HeightMap;12;0;Create;True;0;0;0;False;0;False;None;d0982a0f83b9b964783ad0e59cc0ece4;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.DotProductOpNode;31;-2901.035,-558.5009;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;222;-2325.784,470.6549;Inherit;False;GGX;-1;;17;a7eb34231cec6ea468bdf48101d3dd0a;0;6;8;FLOAT;0;False;9;FLOAT3;0,0,0;False;10;FLOAT;0;False;13;FLOAT;0;False;11;FLOAT;0;False;12;FLOAT;0;False;2;FLOAT3;15;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;207;-1201.858,549.4965;Inherit;False;206;IndirectSpecularCornea;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;150;-2581.392,572.7711;Inherit;False;95;IrisNdotL;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;145;-2583.43,715.4799;Inherit;False;143;IrisVdotH;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.NegateNode;26;-3440.546,-655.918;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;9;-4018.513,-507.7996;Inherit;False;Property;_CorneaNormalStrength;CorneaNormalStrength;3;0;Create;True;0;0;0;False;0;False;1;1;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.TransformDirectionNode;23;-3495.136,-584.7857;Inherit;False;Tangent;World;True;Fast;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleAddOpNode;175;-2363.157,1276.669;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;137;-2582.258,500.6633;Inherit;False;135;IrisNdotH;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;271;-2065.127,105.9749;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TexturePropertyNode;15;-4074.626,640.0743;Inherit;True;Property;_RoughnessTex;RoughnessTex;10;0;Create;True;0;0;0;False;0;False;None;2a932dc32258b5f4390519c1893460ae;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.SamplerNode;61;-3827.079,920.8946;Inherit;True;Property;_TextureSample5;Texture Sample 5;14;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;21;-4042.816,-700.9992;Inherit;True;Property;_TextureSample0;Texture Sample 0;14;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TexturePropertyNode;7;-4259.393,-700.6357;Inherit;True;Property;_CorneaNormal;CorneaNormal;2;0;Create;True;0;0;0;False;0;False;None;03f35acb8b348bf46955dac8a729afd2;True;bump;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.RangedFloatNode;20;-3815.856,555.9282;Inherit;False;Property;_Metallic;Metallic;9;0;Create;True;0;0;0;False;0;False;1;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;34;-2755,-411.1202;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;45;-3838.998,366.5435;Inherit;True;Property;_TextureSample3;Texture Sample 3;14;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;51;-3834.943,638.501;Inherit;True;Property;_TextureSample4;Texture Sample 4;14;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;147;-2582.884,643.285;Inherit;False;92;IrisNdotV;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;85;-2311.525,-9.643145;Inherit;False;float FD90 = 0.5 + 2 * LdotH * LdotH * Roughness@$float FdV = 1 + (FD90 - 1) * (1 - NdotV) * (1 - NdotV) * (1 - NdotV) * (1 - NdotV) * (1 - NdotV)@$float FdL = 1 + (FD90 - 1) * (1 - NdotL) * (1 - NdotL) * (1 - NdotL) * (1 - NdotL) * (1 - NdotL)@$return DiffuseColor * ((1.0 / 3.14159265) * FdV * FdL)@;3;False;5;True;DiffuseColor;FLOAT3;0,0,0;In;;Inherit;False;True;Roughness;FLOAT;0;In;;Inherit;False;True;NdotV;FLOAT;0;In;;Inherit;False;True;NdotL;FLOAT;0;In;;Inherit;False;True;LdotH;FLOAT;0;In;;Inherit;False;DisneyDiffuse;True;False;0;5;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.UnpackScaleNormalNode;22;-3716.371,-581.022;Inherit;False;2;0;FLOAT4;0,0,0,0;False;1;FLOAT;1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.GetLocalVarNode;193;-1218.641,471.3488;Inherit;False;190;GGXSpecularColorCornea;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.OneMinusNode;49;-3209.897,533.8843;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;224;-1390.721,1007.413;Inherit;False;Fresnel;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;111;-3048.551,1437.123;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;62;-3522.079,943.8951;Inherit;False;IrisSpecularMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;13;-2785.212,-804.1099;Inherit;True;Property;_IrisMask;IrisMask;7;0;Create;True;0;0;0;False;0;False;None;d962ebae25be67841aeabead77c47c67;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.SaturateNode;114;-3082.206,-34.0549;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;67;-3588.025,1384.294;Inherit;False;66;IrisReflectDir;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;103;-2554.044,182.0377;Inherit;False;102;IrisLdotH;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;196;-2014.901,1013.592;Inherit;False;CorneaF0;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;205;-3047.111,1659.747;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;FLOAT;0.5283019;False;2;FLOAT3;0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.DotProductOpNode;183;-2051.405,1373.346;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;109;-691.0336,245.9336;Inherit;False;5;5;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;COLOR;0,0,0,0;False;3;FLOAT3;0,0,0;False;4;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;104;-2557.044,109.0375;Inherit;False;95;IrisNdotL;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;113;-3086.206,-124.0549;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;52;-3509.26,689.4795;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;99;-3207.172,152.4232;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;59;-4301.474,410.1502;Inherit;False;42;UVOffset;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;136;-2627.327,357.1642;Inherit;False;53;RoughnessValue;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.NegateNode;30;-3049.839,-604.5824;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SaturateNode;182;-1925.518,1279.846;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;18;-3680.171,1198.244;Inherit;True;Property;_EnvCubemap;EnvCubemap;14;0;Create;True;0;0;0;False;0;False;None;640467d4d57e8774da232dcc1eacf758;False;white;LockedToCube;Cube;-1;0;2;SAMPLERCUBE;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.GetLocalVarNode;199;-3785.164,1863.406;Inherit;False;195;CorneaRoughness;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;82;-2906.257,506.6422;Inherit;False;DiffuseColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;102;-2930.597,144.1942;Inherit;False;IrisLdotH;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;212;-2005.759,538.8959;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;143;-2927.896,331.9389;Inherit;False;IrisVdotH;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;92;-2943.511,-127.6684;Inherit;False;IrisNdotV;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;69;-3553.949,1457.943;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;6;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;79;-3211.513,430.0539;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;80;-3039.96,424.2569;Inherit;False;SpecularColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SaturateNode;184;-1925.406,1372.346;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;206;-2918.561,1654.605;Inherit;False;IndirectSpecularCornea;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;68;-3772.949,1452.943;Inherit;False;53;RoughnessValue;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;87;-2599.259,-38.65295;Inherit;False;53;RoughnessValue;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;203;-3749.521,1651.521;Inherit;False;202;CorneaReflectDir;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;135;-2927.918,238.5798;Inherit;False;IrisNdotH;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;202;-2988.12,-415.2185;Inherit;False;CorneaReflectDir;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;223;-1697.289,1087.614;Inherit;False;GGX;-1;;18;a7eb34231cec6ea468bdf48101d3dd0a;0;6;8;FLOAT;0;False;9;FLOAT3;0,0,0;False;10;FLOAT;0;False;13;FLOAT;0;False;11;FLOAT;0;False;12;FLOAT;0;False;2;FLOAT3;15;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;123;-919.1181,177.1672;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WireNode;166;-2049.212,-489.6345;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;204;-3262.569,1815.351;Inherit;False;196;CorneaF0;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;35;-2662.685,-536.7703;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;179;-2058.67,1186.835;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;8;-4253.557,-109.5905;Inherit;True;Property;_IrisNormal;IrisNormal;4;0;Create;True;0;0;0;False;0;False;None;2ba8641ef16f8be44a253d5809f4847f;True;bump;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.SimpleAddOpNode;56;-1984.334,-693.4296;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SaturateNode;186;-1928.318,1089.845;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;41;-2188.001,-602.1638;Inherit;False;4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT2;0,0;False;3;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SaturateNode;141;-3059.896,337.4389;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;195;-2023.618,940.1224;Inherit;False;CorneaRoughness;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;112;-3292.47,1549.259;Inherit;False;80;SpecularColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;106;-3495.05,86.97211;Inherit;False;89;RefractViewDir;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;190;-1407.733,1102.298;Inherit;False;GGXSpecularColorCornea;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;96;-3216.068,54.4985;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;27;-3450.718,-445.2538;Inherit;False;Constant;_IOR;IOR;14;0;Create;True;0;0;0;False;0;False;0.751879;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;64;-3387.264,1361.143;Inherit;True;Property;_TextureSample6;Texture Sample 6;14;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;MipLevel;Cube;8;0;SAMPLERCUBE;;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;213;-2288.825,675.7033;Inherit;False;62;IrisSpecularMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;66;-2989.826,-321.3831;Inherit;False;IrisReflectDir;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SaturateNode;180;-1926.67,1186.835;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NormalizeNode;176;-2248.156,1275.669;Inherit;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TexturePropertyNode;12;-4074.523,920.1955;Inherit;True;Property;_IrisSpecularMask;IrisSpecularMask;6;0;Create;True;0;0;0;False;0;False;None;6d2b0bf80d3abc34792d973830dc94d0;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.SamplerNode;40;-2562.994,-804.1877;Inherit;True;Property;_TextureSample2;Texture Sample 2;14;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;86;-2575.346,-109.9836;Inherit;False;82;DiffuseColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;194;-3381.699,1627.245;Inherit;True;Property;_TextureSample9;Texture Sample 9;14;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;MipLevel;Cube;8;0;SAMPLERCUBE;;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SaturateNode;119;-3069.206,150.2451;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;225;-3255.502,1893.196;Inherit;False;224;Fresnel;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;154;-1162.895,312.935;Inherit;False;153;GGXSpecularColorIris;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ReflectOpNode;65;-3149.746,-316.6813;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;105;-2553.044,33.03741;Inherit;False;92;IrisNdotV;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;81;-3041.857,511.6422;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;144;-2609.342,429.5348;Inherit;False;80;SpecularColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.ReflectOpNode;201;-3151.635,-411.6505;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;210;-3530.321,1783.282;Inherit;False;2;2;0;FLOAT;6;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LightColorNode;270;-2250.127,158.9749;Inherit;False;0;3;COLOR;0;FLOAT3;1;FLOAT;2
Node;AmplifyShaderEditor.GetLocalVarNode;75;-1174.082,145.9002;Inherit;False;108;DisneyDiffuseColor;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;122;-1221.118,223.1672;Inherit;False;Property;_DiffuseColorStrength;DiffuseColorStrength;1;0;Create;True;0;0;0;False;0;False;1;3.14;0;3.14159;0;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;133;-3069.918,242.5798;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;280;-504.7562,245.6745;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;False;True;1;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;0;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;281;-504.7562,245.6745;Float;False;True;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;Eye;2992e84f91cbeb14eab234972e07ea9d;True;Forward;0;1;Forward;8;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;False;True;1;1;False;-1;0;False;-1;1;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;LightMode=UniversalForward;False;0;Hidden/InternalErrorShader;0;0;Standard;22;Surface;0;  Blend;0;Two Sided;1;Cast Shadows;1;  Use Shadow Threshold;0;Receive Shadows;1;GPU Instancing;1;LOD CrossFade;0;Built-in Fog;0;DOTS Instancing;0;Meta Pass;0;Extra Pre Pass;0;Tessellation;0;  Phong;0;  Strength;0.5,False,-1;  Type;0;  Tess;16,False,-1;  Min;10,False,-1;  Max;25,False,-1;  Edge Length;16,False,-1;  Max Displacement;25,False,-1;Vertex Position,InvertActionOnDeselection;1;0;5;False;True;True;True;False;False;;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;282;-504.7562,245.6745;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;-1;True;3;False;-1;False;True;1;LightMode=ShadowCaster;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;283;-504.7562,245.6745;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;True;False;False;False;False;0;False;-1;False;False;False;False;False;False;False;False;False;True;1;False;-1;False;False;True;1;LightMode=DepthOnly;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;284;-504.7562,245.6745;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
WireConnection;77;0;76;0
WireConnection;77;1;10;0
WireConnection;131;0;78;0
WireConnection;131;1;134;0
WireConnection;108;0;271;0
WireConnection;97;0;98;0
WireConnection;140;0;72;0
WireConnection;181;0;172;0
WireConnection;181;1;174;0
WireConnection;33;0;32;1
WireConnection;33;1;31;0
WireConnection;142;0;106;0
WireConnection;142;1;134;0
WireConnection;165;0;56;0
WireConnection;36;0;35;0
WireConnection;98;0;96;0
WireConnection;139;0;72;0
WireConnection;42;0;166;0
WireConnection;46;0;47;0
WireConnection;25;0;26;0
WireConnection;25;1;23;0
WireConnection;25;2;27;0
WireConnection;29;0;28;0
WireConnection;38;0;37;1
WireConnection;38;1;37;2
WireConnection;93;0;78;0
WireConnection;93;1;94;0
WireConnection;53;0;52;0
WireConnection;89;0;30;0
WireConnection;168;0;23;0
WireConnection;185;0;172;0
WireConnection;185;1;173;0
WireConnection;76;0;8;0
WireConnection;76;1;59;0
WireConnection;78;0;77;0
WireConnection;153;0;212;0
WireConnection;32;0;16;0
WireConnection;37;0;34;0
WireConnection;91;0;78;0
WireConnection;91;1;106;0
WireConnection;70;0;111;0
WireConnection;47;0;45;1
WireConnection;47;1;20;0
WireConnection;72;0;5;0
WireConnection;72;1;59;0
WireConnection;95;0;114;0
WireConnection;31;0;30;0
WireConnection;31;1;29;0
WireConnection;222;8;136;0
WireConnection;222;9;144;0
WireConnection;222;10;137;0
WireConnection;222;13;150;0
WireConnection;222;11;147;0
WireConnection;222;12;145;0
WireConnection;26;0;24;0
WireConnection;23;0;22;0
WireConnection;175;0;173;0
WireConnection;175;1;174;0
WireConnection;271;0;85;0
WireConnection;271;1;270;1
WireConnection;61;0;12;0
WireConnection;61;1;59;0
WireConnection;21;0;7;0
WireConnection;34;0;36;0
WireConnection;34;1;25;0
WireConnection;45;0;14;0
WireConnection;45;1;59;0
WireConnection;51;0;15;0
WireConnection;51;1;59;0
WireConnection;85;0;86;0
WireConnection;85;1;87;0
WireConnection;85;2;105;0
WireConnection;85;3;104;0
WireConnection;85;4;103;0
WireConnection;22;0;21;0
WireConnection;22;1;9;0
WireConnection;49;0;46;0
WireConnection;224;0;223;15
WireConnection;111;0;64;0
WireConnection;111;1;112;0
WireConnection;62;0;61;1
WireConnection;114;0;93;0
WireConnection;196;0;171;0
WireConnection;205;0;194;0
WireConnection;205;1;204;0
WireConnection;205;2;225;0
WireConnection;183;0;176;0
WireConnection;183;1;174;0
WireConnection;109;0;123;0
WireConnection;109;1;154;0
WireConnection;109;2;110;0
WireConnection;109;3;193;0
WireConnection;109;4;207;0
WireConnection;113;0;91;0
WireConnection;52;0;51;1
WireConnection;52;1;19;0
WireConnection;99;0;94;0
WireConnection;99;1;134;0
WireConnection;30;0;25;0
WireConnection;182;0;181;0
WireConnection;82;0;81;0
WireConnection;102;0;119;0
WireConnection;212;0;222;0
WireConnection;212;1;213;0
WireConnection;143;0;141;0
WireConnection;92;0;113;0
WireConnection;69;0;68;0
WireConnection;79;0;139;0
WireConnection;79;1;46;0
WireConnection;80;0;79;0
WireConnection;184;0;183;0
WireConnection;206;0;205;0
WireConnection;135;0;133;0
WireConnection;202;0;201;0
WireConnection;223;8;195;0
WireConnection;223;9;196;0
WireConnection;223;10;180;0
WireConnection;223;13;186;0
WireConnection;223;11;182;0
WireConnection;223;12;184;0
WireConnection;123;0;75;0
WireConnection;123;1;122;0
WireConnection;166;0;165;0
WireConnection;35;0;33;0
WireConnection;179;0;172;0
WireConnection;179;1;176;0
WireConnection;56;0;55;0
WireConnection;56;1;41;0
WireConnection;186;0;185;0
WireConnection;41;0;40;1
WireConnection;41;1;17;0
WireConnection;41;2;39;0
WireConnection;41;3;38;0
WireConnection;141;0;142;0
WireConnection;195;0;170;0
WireConnection;190;0;223;0
WireConnection;96;0;106;0
WireConnection;96;1;94;0
WireConnection;64;0;18;0
WireConnection;64;1;67;0
WireConnection;64;2;69;0
WireConnection;66;0;65;0
WireConnection;180;0;179;0
WireConnection;176;0;175;0
WireConnection;40;0;13;0
WireConnection;194;0;18;0
WireConnection;194;1;203;0
WireConnection;194;2;210;0
WireConnection;119;0;99;0
WireConnection;65;0;26;0
WireConnection;65;1;78;0
WireConnection;81;0;140;0
WireConnection;81;1;49;0
WireConnection;201;0;26;0
WireConnection;201;1;23;0
WireConnection;210;1;199;0
WireConnection;133;0;131;0
WireConnection;281;2;109;0
ASEEND*/
//CHKSM=AE62F30986D64633975924FA5714C2BC0F4112C1