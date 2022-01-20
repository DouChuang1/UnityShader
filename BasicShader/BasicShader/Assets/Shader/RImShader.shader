// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "TA01/RimShader"
{
    Properties
    {
	   _MainTex("texture",2D)="white"{}
       _Emiss("Emiss",Float)=0.0
	   _RimPower("RimPower",Float)=1.0
	   _Range("range",Range(0.0,1.0))=0.0
	   _Vector("vector",Vector)=(0,0,0,0)
	   _MainColor("MainColor",Color)=(0.5,0.5,0.5,1)
	   [Enum(UnityEngine.Rendering.CullMode)]_CullMode("CullMode",float)=2
    }
    SubShader
    {
		Tags{"Queue"="Transparent"}

		pass
		{
			Cull Off
			ZWrite On
			ColorMask 0
			CGPROGRAM
			float4 _Color;

			#pragma vertex vert
			#pragma fragment frag

			float4 vert(float4 vertexPos:POSITION) : SV_POSITION
			{
				return UnityObjectToClipPos(vertexPos);
			}

			float4 frag(void):COLOR
			{
				return _Color;
			}
			ENDCG
		}
       pass
	   {	
			ZWrite On
			//Blend SrcAlpha OneMinusSrcAlpha
			Blend SrcAlpha One
			Cull [_CullMode]
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv:TEXCOORD0;  //第一套UV
				float3 normal:NORMAL;
			};
			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0; //通用的寄存器
				float3 normal_world:TEXCOORD1;
				float3 view_world:TEXCOORD2;
			};

			float4 _MainColor;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _Emiss;
			float _RimPower;
			v2f vert(appdata v)
			{
				v2f o;
				o.pos =UnityObjectToClipPos(v.vertex);

				o.normal_world = normalize(mul(float4(v.normal,0),unity_WorldToObject).xyz);
				float3 pos_world = mul(unity_ObjectToWorld,v.vertex).xyz;
				o.view_world = normalize(_WorldSpaceCameraPos.xyz-pos_world);
				o.uv = v.uv*_MainTex_ST.xy+_MainTex_ST.zw;
				return o;
			}

			float4 frag(v2f i): SV_Target
			{
				float3 normal_world = normalize(i.normal_world);
				float3 view_world = normalize(i.view_world);
				float nDotv = saturate(dot(normal_world,view_world));
				float3 col = _MainColor.xyz*_Emiss;
				float fresnel = pow(1.0-nDotv,_RimPower);
				float rim = saturate(fresnel*_Emiss);
				
				return float4(col,rim);
			}
			ENDCG
	   }
    }
}
