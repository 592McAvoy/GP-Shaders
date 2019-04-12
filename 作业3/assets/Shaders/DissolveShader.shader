Shader "Unlit/DissolveShader"
{
    Properties
    {
		//for Cel-Shadeded Lighting
        _MainTex ("Texture", 2D) = "white" {}
		_RampTex("Ramp Texture", 2D) = "white"{}
		_Color("Color", Color) = (1,1,1,1)

		//for Dissolvation
		_NoiseTex("Noise Texture", 2D) = "white" {}
		_DissolveSpeed("Dissolve Speed", float) = 1.0
		_DissolveColor("Dissolve Edge Color", Color) = (1,1,1,1)
		_ColorThreshold("Color Threshold", float) = 0.1
    }
    SubShader
    {
        Tags 
		{ 
			//"RenderType"="Opaque" 
			"lightMode" = "ForwardBase"
		}
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"	
			#include "UnityStandardBRDF.cginc"

            struct appdata
            {
				float4 position: POSITION;	
				float3 normal: NORMAL;
				float2 uv: TEXCOORD0;
            };

            struct v2f
            {
				float4 position: SV_POSITION;
				float2 uv: TEXCOORD0;
				float3 normal: TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

			sampler2D _RampTex;

			float4 _Color;

			sampler2D _NoiseTex;
			float4 _NoiseTex_ST;

			float _DissolveSpeed;
			float4 _DissolveColor;
			float _ColorThreshold;

            v2f vert (appdata v)
            {
                v2f o;
                o.position = UnityObjectToClipPos(v.position);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.normal = UnityObjectToWorldNormal(v.normal);
				
                return o;
            }

            fixed4 frag (v2f i) : COLOR
            {
				float3 color = _Color.rgb;

				float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
				
				// finds location on ramp texture that we should sample
				// based on angle between surface normal and light direction
				float ramp = DotClamped(lightDir, i.normal);
				float3 lighting = tex2D(_RampTex, float2(ramp, 0.5)).rgb;
				
                // sample the texture
                fixed4 albedo = tex2D(_MainTex, i.uv);                

				// sample noise texture
			 	float noiseSample = tex2Dlod(_NoiseTex, float4(i.uv, 0, 0));
				
				// edge threshold
				float thresh = _Time * (_ColorThreshold + _DissolveSpeed);
				float useDissolve = noiseSample - thresh < 0;
				color = (1 - useDissolve)*color + useDissolve * _DissolveColor.rgb;
				
				// delete choised pixels
				float threshold = _Time * _DissolveSpeed;
				clip(noiseSample - threshold);

				// final color
				float3 rgb = albedo.rgb * lighting * color;

				return float4(rgb, 1.0);
            }
            ENDCG
        }
    }
}
