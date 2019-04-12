Shader "Unlit/WaterShader"
{
	Properties
	{
		// color of the water
		_Color("Color", Color) = (1, 1, 1, 1)
		_EdgeColor("Edge Color", Color) = (1, 1, 1, 1)
		_DepthFactor("Depth Factor", float) = 1.0
		_MainTex("Main Texture", 2D) = "white"{}
		
		// texture of the depth ramp
		_DepthRampTex("Depth Ramp Texture", 2D) = "white" {}
		
		//params for water wave
		_WaveSpeed("Wave Speed", float) = 1.0
		_WaveAmp("Wave Amp", float) = 1.0
		_NoiseTex("Noise Texture", 2D) = "white" {}	
		_ExtraHeight("Extra Height", float) = 0.0

		//distortion
		_DistortStrength("Distort Strength", float) = 0.5
	}

	SubShader
	{
		GrabPass
		{
			"_BackgroundTexture"
		}

			// distortion
		Pass
		{
			Tags
			{
				"Queue" = "Transparent"
			}

			Cull Off
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#pragma shader_feature USE_WAVE

			#include "UnityCG.cginc"
			sampler2D _BackgroundTexture;

			float _DistortStrength;
			float _WaveSpeed;
			float _WaveAmp;
			sampler2D _NoiseTex;

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv: TEXCOORD0;
				float3 normal: NORMAL;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float4 grabPos: TEXCOORD0;
			};


			v2f vert(appdata v)
			{
				v2f o;

				o.pos = UnityObjectToClipPos(v.vertex);
				o.grabPos = ComputeGrabScreenPos(o.pos);

				float noiseSample = tex2Dlod(_NoiseTex, float4(v.uv, 0, 0));
				o.grabPos.y += sin(_Time*_WaveSpeed*noiseSample)*_WaveAmp*_DistortStrength;
				o.grabPos.x += cos(_Time*_WaveSpeed*noiseSample)*_WaveAmp*_DistortStrength;

				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				return tex2Dproj(_BackgroundTexture, i.grabPos);
			}
			ENDCG
		}

		Pass
		{
			Tags
			{
				"Queue" = "Transparent"
				"lightMode" = "ForwardBase"
			}

			Cull Off
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag


			#pragma shader_feature RAMP_TEX
			#pragma shader_feature USE_WAVE


			#include "UnityCG.cginc"
			float4 _Color;
			float4 _EdgeColor;
			float _DepthFactor;

			sampler2D _CameraDepthTexture;

			sampler2D _MainTex;
			float4 _MainTex_ST;

			sampler2D _DepthRampTex;

			float _WaveSpeed;
			float _WaveAmp;
			sampler2D _NoiseTex;
			float _ExtraHeight;

            struct appdata
            {
                float4 vertex : POSITION;
				float2 uv: TEXCOORD0;
				float3 normal: NORMAL;
            };

            struct v2f
            {                
                float4 pos : SV_POSITION;
				float2 uv: TEXCOORD0;
				float4 screenPos : TEXCOORD1;
				float3 normal: TEXCOORD2;
            };


            v2f vert (appdata v)
            {
                v2f o;
                
				o.pos = UnityObjectToClipPos(v.vertex);
				o.screenPos = ComputeScreenPos(o.pos);
				o.uv = v.uv;
				o.normal = UnityObjectToWorldNormal(v.normal);

				// apply wave animation
				#if USE_WAVE
					float noiseSample = tex2Dlod(_NoiseTex, float4(v.uv, 0, 0));
					o.pos.y += sin(_Time*_WaveSpeed*noiseSample)*_WaveAmp + _ExtraHeight;
					o.pos.x += cos(_Time*_WaveSpeed*noiseSample)*_WaveAmp;
				#endif

                return o;
            }

            fixed4 frag (v2f i) : COLOR
            {
                
				// sample camera depth texture
				float4 depthSample = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, i.screenPos);
				float depth = LinearEyeDepth(depthSample).r;

				// apply the DepthFactor to be able to tune at what depth values
				// the foam line actually starts
				float foamLine = 1 - saturate(_DepthFactor * (depth - i.screenPos.w));
				
				
				// multiply the edge color by the foam factor to get the edge,
				// then add that to the color of the water				
				float4 col = _Color + foamLine * _EdgeColor;				

				// sample the ramp texture
				#if RAMP_TEX
					float4 foamRamp = float4(tex2D(_DepthRampTex, float2(foamLine, 0.5)).rgb, 1.0);
					col = _Color * foamRamp;
				#endif

				float4 albedo = tex2D(_MainTex, i.uv);
				
				return col * albedo;
            }
            ENDCG
        }
    }
	CustomEditor "WaterShaderGUI"
}
