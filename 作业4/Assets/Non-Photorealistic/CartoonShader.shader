Shader "Unlit/CartoonShader"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
		_LightWarpTex("Light Warping Texture", 2D) = "white" {}
		_CubeMap("Ambient Cube Map",CUBE) = ""{}
		_kSpec("Shininess", float) = 10
		_specColor("Specular Color", Color) = (0.9,0.9,0.9,1)
		_rimAmount("Rim Amount", Range(0,1)) = 0.716
		_rimColor("Rim Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags
		{ 
			"RenderType"="Opaque" 
			"LightMode" = "ForwardBase"
		}
        LOD 100

        Pass
        {
            CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
            
			#include "UnityCG.cginc"
			#include "UnityStandardBRDF.cginc"////dotclamped
			#include "AutoLight.cginc"
			#include "Lighting.cginc"

			sampler2D _MainTex;//纹理
			float4 _MainTex_ST;//纹理缩放/偏移

			sampler2D _LightWarpTex;//纹理
			float4 _LightWarpTex_ST;//纹理缩放/偏移

			samplerCUBE _CubeMap;

			float _kSpec;
			float4 _specColor;
			float _rimAmount;
			float4 _rimColor;			

			float3 Schlick_F(half3 R, half LdotH)
			{
				//// TODO: your implementation
				float3 F = R + (float3(1, 1, 1) - R) * pow((1 - LdotH), 5);
				return F;
			}

			struct VertexData {
				float4 position: POSITION;	// 类型 变量：语义
				float3 normal: NORMAL;
				float2 uv: TEXCOORD0;
				float4 tangent : TANGENT;
			};
			struct FragmentData {
				float4 position: SV_POSITION;
				float2 uv: TEXCOORD0;
				float3 normal: TEXCOORD4;
				float3 worldPos: TEXCOORD5;
				// these three vectors will hold a 3x3 rotation matrix
				// that transforms from tangent to world space
				half3 tspace0 : TEXCOORD1; // tangent.x, bitangent.x, normal.x
				half3 tspace1 : TEXCOORD2; // tangent.y, bitangent.y, normal.y
				half3 tspace2 : TEXCOORD3; // tangent.z, bitangent.z, normal.z
			};

			FragmentData vert(VertexData v)
			{
				FragmentData o;
				o.position = UnityObjectToClipPos(v.position);
				o.normal = UnityObjectToWorldNormal(v.normal);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.worldPos = mul(unity_ObjectToWorld, v.position);
	
				half3 wNormal = o.normal;
				half3 wTangent = UnityObjectToWorldDir(v.tangent.xyz);
				// compute bitangent from cross product of normal and tangent
				half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				half3 wBitangent = cross(wNormal, wTangent) * tangentSign;
				// output the tangent space matrix
				o.tspace0 = half3(wTangent.x, wBitangent.x, wNormal.x);
				o.tspace1 = half3(wTangent.y, wBitangent.y, wNormal.y);
				o.tspace2 = half3(wTangent.z, wBitangent.z, wNormal.z);

				return o;
			}

			float4 frag(FragmentData i) : SV_TARGET
			{
				//// Vectors
				float3 L = normalize(lerp(_WorldSpaceLightPos0.xyz, _WorldSpaceLightPos0.xyz - i.worldPos.xyz,_WorldSpaceLightPos0.w));
				float3 V = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
				float3 H = Unity_SafeNormalize(L + V);

				float3 tnormal = i.normal;
				// transform normal from tangent to world space
				float3 N;
				N.x = dot(i.tspace0, tnormal);
				N.y = dot(i.tspace1, tnormal);
				N.z = dot(i.tspace2, tnormal);

				//// Vector dot
				float NdotL = saturate(dot(N,L));
				float NdotH = saturate(dot(N,H));
				float NdotV = saturate(dot(N,V));
				float VdotH = saturate(dot(V,H));
				float LdotH = saturate(dot(L,H));

				float3 albedo = tex2D(_MainTex, i.uv).rgb; //k_d

				float3 lightColor = _LightColor0.rgb;	//c

				//// 1. View Independent Lighting Terms
				//// 1.1 Half Lambert
				float alpha = 0.5;
				float beta = 0.5;
				float gamma = 1;
				float3 halfLambert = pow(alpha * NdotL + beta, gamma);

				//// 1.2 Diffuse Warping Function
				float ramp = saturate(halfLambert);
				float3 warpedRGB = tex2D(_LightWarpTex, float2(ramp, 0.5)).rgb;
				float3 warpedLight = lightColor * warpedRGB;

				//// 1.3 Directional Ambient Term
				half3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				half3 worldRefl = reflect(-worldViewDir, N);
				half3 ambient = texCUBE(_CubeMap, worldRefl).rgb;

				float3 viewIndependentLight = albedo * (ambient + warpedLight);

				//// 2. View Dependent Lighting Terms
				//// 2.1 Specular
				float specularIntensity = pow(NdotH, _kSpec);
				float specularIntensitySmooth = smoothstep(0.005, 0.01, specularIntensity);
				float3 F_s = Schlick_F(_specColor.rgb, LdotH);
				float3 specular = F_s * specularIntensitySmooth * lightColor;

				//// 2.2 Rim Lighting
				float4 rimDot = NdotV;
				float rimIntensity = smoothstep(_rimAmount - 0.01, _rimAmount + 0.01, rimDot);
				float3 F_r = Schlick_F(_rimColor.rgb, LdotH);
				float3 rim = F_r * rimIntensity * pow(NdotL, _rimAmount);

				float3 viewDependentLight = albedo * (specular + rim);

				// return float4(albedo, 1);	// (a) Albedo
				// return float4(warpedLight, 1);	//(b) Warped Light
				// return float4(ambient, 1);	//(c) Ambient Cube
				// return float4(ambient + warpedLight, 1);	//(d) Cb)+(c)				
				// return float4(viewIndependentLight, 1); //(e) (a)*(d)
				// return float4(specular, 1);	//(f) Specular
				// return float4(rim, 1);	//(g) Rim lighting
				// return float4(specular+rim, 1);	//(g) Specular + Rim lighting
				return float4(viewDependentLight + viewIndependentLight, 1);


			}


            ENDCG
        }
    }
}
