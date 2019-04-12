// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/FogLocal"
{
	Properties
	{
		_MainTex("Base (RGB)", 2D) = "white" {}
		_Ramp("Ramp Texture", 2D) = "white" {}
		_Tooniness("Tooniness", Range(0.1,20)) = 4
		_Outline("Outline", Range(0,1)) = 0.1

		_FogColor("Fog Color", Color) = (1, 0, 0, 0)
		_FogIntensity("Fog Intensity", float) = 0.1
		_FogStart("Fog Start", float) = 0
		_FogEnd("Fog End", float) = 300
	}
	SubShader{
		Tags { "RenderType" = "Opaque" }
		LOD 200

		CGINCLUDE
		#include "UnityCG.cginc" 

		sampler2D _MainTex;
		sampler2D _Ramp;

		float4 _MainTex_ST;

		float _Tooniness;
		float _Outline;

		float4 _FogColor;
		float _FogIntensity;
		float _FogStart;
		float _FogEnd;

		float4 SimulateFog(float4 pos, float4 col)
		{
			pos.w = 0.0;
			float dist = length(pos);
//			float dist = pos.z;

			// Linear
			float fogFactor = (_FogEnd - abs(dist)) / (_FogEnd - _FogStart);
			fogFactor = clamp(fogFactor, 0.0, 1.0);
					
			// Exponential
//			float fogFactor = exp(-abs(_FogIntensity * dist));
//			fogFactor = clamp(fogFactor, 0.0, 1.0);

			// Exp2
//			float fogFactor = exp(-(_FogIntensity * dist) * (_FogIntensity * dist));
//			fogFactor = clamp(fogFactor, 0.0, 1.0);

			float3 afterFog = lerp(_FogColor.rgb, col.rgb, fogFactor);
			return float4(afterFog, col.a);
		}

		ENDCG

			Pass{
				Tags { "LightMode" = "ForwardBase" }

				Cull Front
				Lighting Off
				ZWrite On

				CGPROGRAM

				#pragma vertex vert
				#pragma fragment frag

				#pragma multi_compile_fwdbase

				#include "UnityCG.cginc"

				struct a2v
				{
					float4 vertex : POSITION;
					float3 normal : NORMAL;
				};

				struct v2f
				{
					float4 pos : POSITION;
					float4 viewSpacePos : TEXCOORD0;
				};

				v2f vert(a2v v)
				{
					v2f o;

					float4 pos = mul(UNITY_MATRIX_MV, v.vertex);
					float3 normal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
					normal.z = -0.5;
					pos = pos + float4(normalize(normal),0) * _Outline;
					o.pos = mul(UNITY_MATRIX_P, pos);

					o.viewSpacePos = mul(UNITY_MATRIX_MV, v.vertex);

					return o;
				}

				float4 frag(v2f i) : COLOR
				{
					return SimulateFog(i.viewSpacePos, float4(0, 0, 0, 1));
				}

				ENDCG
		}

		Pass
		{
			Tags { "LightMode" = "ForwardBase" }

			Cull Back
			Lighting On

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#pragma multi_compile_fwdbase

			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			#include "UnityShaderVariables.cginc"

			struct a2v
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
				float4 tangent : TANGENT;
			};

			struct v2f
			{
				float4 pos : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : TEXCOORD1;
				float4 viewSpacePos : TEXCOORD2;
				LIGHTING_COORDS(3,4)
			};

			v2f vert(a2v v)
			{
				v2f o;

				//Transform the vertex to projection space
				o.pos = UnityObjectToClipPos(v.vertex);
				o.normal = mul((float3x3)unity_ObjectToWorld, SCALED_NORMAL);
				//Get the UV coordinates
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

				o.viewSpacePos = mul(UNITY_MATRIX_MV, v.vertex);

				// pass lighting information to pixel shader
				TRANSFER_VERTEX_TO_FRAGMENT(o);
				return o;
			}

			float4 frag(v2f i) : COLOR
			{
				//Get the color of the pixel from the texture
				float4 c = tex2D(_MainTex, i.uv);
				//Merge the colours
				c.rgb = (floor(c.rgb*_Tooniness) / _Tooniness);

				//Based on the ambient light
				float3 lightColor = UNITY_LIGHTMODEL_AMBIENT.xyz;

				//Work out this distance of the light
				float atten = LIGHT_ATTENUATION(i);
				//Angle to the light
				float diff = dot(normalize(i.normal), normalize(_WorldSpaceLightPos0.xyz));
				diff = diff * 0.5 + 0.5;
				//Perform our toon light mapping 
				diff = tex2D(_Ramp, float2(diff, 0.5));
				//Update the colour
				lightColor += _LightColor0.rgb * (diff * atten);
				//Product the final color
				c.rgb = lightColor * c.rgb * 2;

				return SimulateFog(i.viewSpacePos, c);
			}

			ENDCG
		}
	}
	FallBack "Diffuse"
}
