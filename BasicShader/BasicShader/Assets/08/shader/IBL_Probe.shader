Shader "Unlit/IBL_Probe"
{
	Properties
	{
		//_MainTex ("Texture", 2D) = "white" {}
		_CubeMap("Cube Map",Cube) = "white"{}
		_Tint("Tint",Color) = (1,1,1,1)
		_Expose("Expose",Float) = 1.0
		_Rotate("Rotate",Range(0,360)) = 0
		_NormalMap("Normal Map",2D) = "bump"{}
		_NormalIntensity("Normal Intensity",Float) = 1.0
		_AOMap("AO Map",2D) = "white"{}
		_AOAdjust("AOAdjust",Range(0,1)) =1
		_RoughnessMap("Roughness Map",2D)="white" {}
		_RoughnessContrast("RoughnessContrast",Range(0,64))=1
		_RoughnessBrightness("RoughnessContrast",Float)=1
		_RoughnessMin("RoughnessMin",Range(0,1))=0
		_RoughnessMax("RoughnessMax",Range(0,1))=1
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
				float2 texcoord : TEXCOORD0;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 pos : SV_POSITION;
				float3 normal_world : TEXCOORD1;
				float3 pos_world : TEXCOORD2;
				float3 tangent_world : TEXCOORD3;
				float3 binormal_world : TEXCOORD4;
			};

			//sampler2D _MainTex;
			//float4 _MainTex_ST;

			samplerCUBE _CubeMap;
			float4 _CubeMap_HDR;
			float4 _Tint;
			float _Expose;

			sampler2D _NormalMap;
			float4 _NormalMap_ST;
			float _NormalIntensity;
			sampler2D _AOMap;
			float _Rotate;
			float _RoughnessContrast;
			float _RoughnessBrightness;
			float _RoughnessMin;
			float _RoughnessMax;
			float _AOAdjust;

			sampler2D _RoughnessMap;

			float3 RotateAround(float degree, float3 target)
			{
				float rad = degree * UNITY_PI / 180;
				float2x2 m_rotate = float2x2(cos(rad), -sin(rad),
					sin(rad), cos(rad));
				float2 dir_rotate = mul(m_rotate, target.xz);
				target = float3(dir_rotate.x, target.y, dir_rotate.y);
				return target;
			}
			
			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord * _NormalMap_ST.xy + _NormalMap_ST.zw;
				o.pos_world = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.normal_world = normalize(mul(float4(v.normal, 0.0), unity_WorldToObject).xyz);
				o.tangent_world = normalize(mul(unity_ObjectToWorld, float4(v.tangent.xyz, 0.0)).xyz);
				o.binormal_world = normalize(cross(o.normal_world, o.tangent_world)) * v.tangent.w;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				half3 normal_dir = normalize(i.normal_world);
				half3 normaldata = UnpackNormal(tex2D(_NormalMap,i.uv));
				normaldata.xy = normaldata.xy* _NormalIntensity;
				half3 tangent_dir = normalize(i.tangent_world);
				half3 binormal_dir = normalize(i.binormal_world);
				normal_dir = normalize(tangent_dir * normaldata.x
					+ binormal_dir * normaldata.y + normal_dir * normaldata.z);

				half ao = tex2D(_AOMap, i.uv).r;
				ao = lerp(1.0,ao,_AOAdjust);
				half3 view_dir = normalize(_WorldSpaceCameraPos.xyz - i.pos_world);
				half3 reflect_dir = reflect(-view_dir, normal_dir);

				reflect_dir = RotateAround(_Rotate, reflect_dir);
				
				//通过修改环境贴图mapping下面的属性 可以生成IBL的环境贴图 之后进行采样
				//定义粗糙度 采样对应的层级 0-9  0最清晰 逐渐模糊粗糙
				//也就是pbr里面的粗糙度的实现
				
				//增加一个粗糙度采样贴图来控制粗糙程度
				float roughness = tex2D(_RoughnessMap,i.uv);
				roughness = saturate(pow(roughness,_RoughnessContrast)*_RoughnessBrightness);
				roughness = lerp(_RoughnessMin,_RoughnessMax,roughness);

				float min_level = roughness*6.0;
				//采样 反射探针的环境贴图
				half4 color_cubemap = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0,reflect_dir,min_level);
				half3 env_color = DecodeHDR(color_cubemap, unity_SpecCube0_HDR);//确保在移动端能拿到HDR信息
				half3 final_color = env_color * ao * _Tint.rgb * _Expose;
				return float4(final_color,1.0);
			}
			ENDCG
		}
	}
}
