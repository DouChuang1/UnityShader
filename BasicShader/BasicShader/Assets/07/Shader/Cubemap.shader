Shader "Unlit/Cubemap"
{
	Properties
	{
		//_MainTex ("Texture", 2D) = "white" {}
		_CubeMap("CueMap",Cube)="white"{}
		_NormalMap ("Normap", 2D) = "bump" {}
		_NormalIntensity("NormalIntensity",Range(0.1,5))=1
		_AOMap("AOMap",2D)="white"{}
		_Tint("Tint",Color) = (1,1,1,1)

		_Rotate("Rotate",Range(0,360))= 0
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
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				float4 tangent:TANGENT;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float3 normal_world : TEXCOORD1;
				float3 pos_world : TEXCOORD2;
				float3 tangent_world : TEXCOORD3;
				float3 binormal_world : TEXCOORD4;
			};

			//sampler2D _MainTex;
			//float4 _MainTex_ST;

			samplerCUBE _CubeMap;
			sampler2D _NormalMap;
			float4 _NormalMap_ST;
			float _NormalIntensity;
			sampler2D _AOMap;
			float4 _CubeMap_HDR;
			float4 _Tint;
			float _Rotate;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv*_NormalMap_ST.xy+_NormalMap_ST.zw;
				o.pos_world = mul(unity_ObjectToWorld,v.vertex).xyz;
				o.normal_world = normalize(mul(float4(v.normal,0),unity_WorldToObject).xyz);
				o.tangent_world = normalize(mul(unity_ObjectToWorld,float4(v.tangent.xyz,0)).xyz);  //世界空间顶点切线
				o.binormal_world = normalize(cross(o.normal_world,o.tangent_world))*v.tangent.w; //最后的乘法是用来处理不同平台下 次法线的反转问题
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float3 normal_world = normalize(i.normal_world);
				half3 tangent_world = normalize(i.tangent_world);
				half3 binormal_world = normalize(i.binormal_world);

				//法线贴图
				half4 normalMap = tex2D(_NormalMap,i.uv);
				half3 normal_data = UnpackNormal(normalMap);

				normal_world = normalize(tangent_world*normal_data.x+binormal_world*normal_data.y*_NormalIntensity+normal_world*normal_data.z);
				float3 view_dir = normalize(_WorldSpaceCameraPos.xyz-i.pos_world);
				float3 reflect_dir = reflect(-view_dir,normal_world);
				
				//旋转贴图 主要旋转反射方向 绕y轴旋转
				//角度转弧度
				float rad = _Rotate*UNITY_PI/180;
				//旋转矩阵
				float2x2 m_rotate = float2x2(cos(rad),-sin(rad),
											sin(rad),cos(rad));

                float2 dir_rotate =mul(m_rotate,reflect_dir.xz);
				reflect_dir = float3(dir_rotate.x,reflect_dir.y,reflect_dir.y);

				//采样环境贴图 
				//float4 color_cubemap = texCUBE(_CubeMap,reflect_dir);

				//采样unity生成的反射探针环境贴图
				half4 color_cubemap = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0,reflect_dir);

				//确保在移动端显示HDR成功 需要进行解码
				float3 decode_cubemap = DecodeHDR(color_cubemap,unity_SpecCube0_HDR);
				float ao = tex2D(_AOMap,i.uv);
				float3 final_color = decode_cubemap*ao*_Tint;
				return float4(final_color,1);
			}
			ENDCG
		}
	}
}
