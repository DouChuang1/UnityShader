// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unlit/ScanCode"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_FlowTex("FlowTex",2D)="white" {}
		_RimMin("RimMin",Range(-1,1))=0.0
		_RimMax("RimMax",Range(0,2))=1.0

		_InnerColor("Inner Color",Color)=(0.0,0.0,0.0,0.0)
		_RimColor("Rim Color",Color)=(0.0,0.0,0.0,0.0)
		_RimIntensity("RimIntensity",Float)=1.0
		_FlowTilling("FlowTilling",vector)=(1,1,0,0)
		_FlowSpeed("FlowSpeed",vector)=(1,1,0,0)
		_FlowIntensity("FlowIntensity",Float)=0.5
		_InnerAlpha("InnerAlpha",Float)=0.1
	}
	SubShader
	{
		Tags { "RenderType"="Transparent" }
		LOD 100

		Pass
		{
			ZWrite Off
			Blend SrcAlpha One
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
				float3 normal : NORMAL;

			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 pos : SV_POSITION;
				float3 pos_world : TEXCOORD1;
				float3 normal_world : TEXCOORD2;
				float3 pivot_world : TEXCOORD3;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			sampler2D _FlowTex;
			float4 _FlowTex_ST;
			float _RimMin;
			float _RimMax;
			float4 _InnerColor;
			float4 _RimColor;
			float _RimIntensity;
			float4 _FlowTilling;
			float4 _FlowSpeed;
			float _FlowIntensity;
			float _InnerAlpha;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

                float3 normal_world = mul(float4(v.normal,0),unity_ObjectToWorld).xyz;
                float3 pos_world = mul(unity_ObjectToWorld,v.vertex).xyz;
                o.normal_world = normalize(normal_world);
                o.pos_world = pos_world;
				o.pivot_world = mul(unity_ObjectToWorld,float4(0,0,0,1));
                o.uv = v.texcoord;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				//边缘光
			    half3 normal_world = normalize(i.normal_world);
			    half3 view_world = normalize(_WorldSpaceCameraPos.xyz-i.pos_world);
			    half NdotV = dot(normal_world,view_world);
			    half fresnel = 1.0-NdotV;
			    fresnel = smoothstep(_RimMin,_RimMax,fresnel);

				//相当于自发光 丰富模型细节
				half emiss = tex2D(_MainTex,i.uv).r;
				emiss = pow(emiss,5);
				half final_fresnel = saturate(fresnel+emiss);

				half3 rim_Color = lerp(_InnerColor.xyz,_RimColor.xyz*_RimIntensity,final_fresnel);
				half rim_alpha = final_fresnel;

				//流光
				half2 uv_flow = (i.pos_world.xy-i.pivot_world.xy)*_FlowTilling.xy;
				uv_flow = uv_flow+_Time.y*_FlowSpeed.xy;
				float4 flow_rgba = tex2D(_FlowTex,uv_flow)*_FlowIntensity;

				float3 final_col = rim_Color+flow_rgba.xyz;
				float final_alpha = saturate(rim_alpha+flow_rgba.a+_InnerAlpha);
				return float4(final_col,final_alpha);
			}
			ENDCG
		}
	}
}
