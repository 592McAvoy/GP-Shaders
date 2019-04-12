Shader "Unlit/MyShader"
{
	Properties
	{
		_MainTex ("Main Texture", 2D) = "white" {}
		_MainColor("Main Color", Color) = (1,1,1,1)	//变量名（“显示名”，类型）=默认值
		_Shininess ("Shininess", float) = 10
	}
	
	SubShader
	{
		Tags { 

			//"Queue" = "Transparent"
		}
		//LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex MyVertexProgram
			#pragma fragment MyFragmentProgram
			
			#pragma shader_feature PURE_COLOR
			#pragma shader_feature NORMAL_ONLY
			#pragma shader_feature TEXTURE_ONLY
			#pragma shader_feature BLINN_PHONG
			#pragma shader_feature USE_SPECULAR

			#include "UnityCG.cginc"
			#include "UnityStandardBRDF.cginc"

			float4 _MainColor;//颜色

			sampler2D _MainTex;//纹理
			float4 _MainTex_ST;//纹理缩放/偏移

			float _Shininess;	//高光乘方系数

			struct VertexData{
				float4 position: POSITION;	// 类型 变量：语义
				float3 normal: NORMAL;
				float2 uv: TEXCOORD0;
			};
			struct FragmentData {
				float4 position: SV_POSITION;
				float2 uv: TEXCOORD0;
				float3 normal: TEXCOORD1;
				float3 worldPos: TEXCOORD2;
			};

			FragmentData MyVertexProgram(VertexData v)
			{
				FragmentData i;
				i.position = UnityObjectToClipPos(v.position);
				i.normal = UnityObjectToWorldNormal(v.normal);
				i.uv = TRANSFORM_TEX(v.uv, _MainTex);
				i.worldPos = mul(unity_ObjectToWorld, v.position);
				return i;
			}

			float4 MyFragmentProgram(FragmentData i): SV_TARGET
			{
				#if PURE_COLOR
					return _MainColor;
				#endif

				#if NORMAL_ONLY
					return float4(i.normal, 1);
				#endif
				 
				#if TEXTURE_ONLY
					return tex2D(_MainTex, i.uv);
				#endif

				#if BLINN_PHONG
					float3 lightDir = _WorldSpaceLightPos0.xyz;
					float3 lightColor = _LightColor0.rgb;
					float3 diffuse = tex2D(_MainTex, i.uv).rgb * lightColor * DotClamped(lightDir, i.normal);
					fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * tex2D(_MainTex, i.uv).rgb;
					
					float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
					float3 halfVector = normalize(lightDir + viewDir);
					float3 specular = float3(0, 0, 0);
					#if USE_SPECULAR 
						specular = pow(DotClamped(i.normal, halfVector), _Shininess);
					#endif

					return float4(ambient + diffuse + specular, 1);
				#endif		

				return _MainColor;
			}
	

	

			ENDCG
		}
	}

	CustomEditor "CustomShaderGUI"
}
