// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "TA01/MiniShader"
{
    Properties
    {
	   _MainTex("texture",2D)="white"{}
       _Float("float",Float)=0.0
	   _Range("range",Range(0.0,1.0))=0.0
	   _Vector("vector",Vector)=(0,0,0,0)
	   _Color("color",Color)=(0.5,0.5,0.5,1)
    }
    SubShader
    {
       pass
	   {
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv:TEXCOORD0;  //第一套UV
			};
			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0; //通用的寄存器
			};

			float4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			v2f vert(appdata v)
			{
				v2f o;
				//float4 worldPos = mul(unity_ObjectToWorld,v.vertex);
				//float4 viewPos = mul(UNITY_MATRIX_V,worldPos);
				//float4 clipPos = mul(UNITY_MATRIX_P,viewPos);
				//o.pos = clipPos;
				o.pos =UnityObjectToClipPos(v.vertex);
				o.uv = v.uv*_MainTex_ST.xy+_MainTex_ST.zw;
				return o;
			}

			float4 frag(v2f i): SV_Target
			{
				float4 col = tex2D(_MainTex,i.uv);
				return col;
			}
			ENDCG
	   }
    }
}
