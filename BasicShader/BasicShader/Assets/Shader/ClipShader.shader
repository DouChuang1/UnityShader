// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "TA01/ClipShader"
{
    Properties
    {
	   _MainTex("texture",2D)="white"{}
	   _NoiseTex("texture",2D)="white"{}
	   _Cutout("Cutout",Range(0.0,1.0))=0.0
	   _Speed("speed",Vector)=(0,0,0,0)
	   _MainColor("MainColor",Color)=(0.5,0.5,0.5,1)
	   [Enum(UnityEngine.Rendering.CullMode)]_CullMode("CullMode",float)=2
    }
    SubShader
    {
       pass
	   {	Cull [_CullMode]
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

			float4 _MainColor;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _Cutout;
			float4 _Speed;

			sampler2D _NoiseTex;
			float4 _NoiseTex_ST;
			v2f vert(appdata v)
			{
				v2f o;
				o.pos =UnityObjectToClipPos(v.vertex);
				o.uv = v.uv*_MainTex_ST.xy+_MainTex_ST.zw;
				return o;
			}

			float4 frag(v2f i): SV_Target
			{
				half gradient = tex2D(_MainTex,i.uv+_Time.y*_Speed.xy).r;
				half noise = tex2D(_NoiseTex,i.uv+_Time.y*_Speed.zw).r;
				clip(gradient-noise-_Cutout);
				return _MainColor;
			}
			ENDCG
	   }
    }
}
