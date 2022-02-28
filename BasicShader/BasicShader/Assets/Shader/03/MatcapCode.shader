// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unlit/MatcapCode"
{
	Properties
	{
		_MainTex ("MainTex", 2D) = "white" {}
		_matcap("Matcap",2D)="white" {}
		_matcapAdd("MatcapAdd",2D)="white" {}
		_RampTex("Ramp",2D)="white" {}
		_matcapIntensity("matcapIntensity",Float)=1.0
		_matcapAddIntensity("matcapAddIntensity",Float)=1.0
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
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float3 normal_world : TEXCOORD1;
				float3 pos_world :TEXCOORD2;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			sampler2D _matcap;
			float4 _matcap_ST;

			sampler2D _RampTex;
			float4 _RampTex_ST;
			float _matcapIntensity;

			sampler2D _matcapAdd;
			float4 _matcapAdd_ST;
			float _matcapAddIntensity;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.normal_world = mul(float4(v.normal,0),unity_WorldToObject).xyz;
				o.pos_world = mul(unity_ObjectToWorld,v.vertex).xyz;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float3 normal_world = normalize(i.normal_world);
				float3 normal_viewSpace = mul(UNITY_MATRIX_V,float4(normal_world,0)).xyz;

				float2 uv_matcap = (normal_viewSpace.xy+float2(1,1))*0.5;
				float4 matcap_color = tex2D(_matcap,uv_matcap)*_matcapIntensity;

				float4 diffuse_color = tex2D(_MainTex,i.uv);
				float4 combined_color = matcap_color*diffuse_color;

				float3 view_dir = normalize(_WorldSpaceCameraPos.xyz - i.pos_world);
				half NdotV = saturate(dot(normal_world,view_dir));
				half fresnel = 1-NdotV;
				half2 uv_ramp = half2(fresnel,0.5);
				half4 ramp_color = tex2D(_RampTex,uv_ramp);

				half4 matcapadd_color = tex2D(_matcapAdd,uv_matcap)*_matcapAddIntensity;

				half4 finalColor = ramp_color*combined_color+matcapadd_color;

				return finalColor;
			}
			ENDCG
		}
	}
}
