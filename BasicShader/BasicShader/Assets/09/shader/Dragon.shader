Shader "Unlit/Dragon"
{
	Properties
	{
		_DiffuseColor ("DiffuseColor", Color) = (1,1,1,1)
		_AddColor ("AddColor", Color) = (1,1,1,1)
		_Distort("Distort",Range(0,1))=1
		_Power("Power",Float)=1  
		_Scale("Scale",Float)=1
		_ThicknessMap("ThicknessMap",2D)="white"{}
		_CubeMap("CueMap",Cube) = "white" {}
		_EnvRotate("Env Rotate",Range(0,360)) = 0
		_Opacity("Opacity",Range(0,1))=1
		_BackLightColor("BackLightColor",Color)= (1,1,1,1)
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			Tags{"LightMode"="ForwardBase"}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			//光照计算需要增加
			#pragma multi_compile_fwdbase 
			#include "AutoLight.cginc"
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
				float4 posWorld : TEXCOORD1;
				float3 normalDir : TEXCOORD2;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _LightColor0;
			float _Distort;
			float _Power;
			float _Scale;
			sampler2D _ThicknessMap;
			samplerCUBE _CubeMap;
			float4 _CubeMap_HDR;
			float _EnvRotate;
			float4 _DiffuseColor;
			float4 _AddColor;
			float _Opacity;
			float4 _BackLightColor;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord;
				o.posWorld = mul(unity_ObjectToWorld, v.vertex);
				o.normalDir = UnityObjectToWorldNormal(v.normal);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				half3 normalDir = normalize(i.normalDir);
				float3 viewDir = normalize(_WorldSpaceCameraPos-i.posWorld);
				float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);

				//漫反射 NdotL 用来提亮背面
				//float3 NdotL = max(0,dot(normal_world,light_world));
				float3 diffuse_color = _DiffuseColor.xyz;
				float3 NdotL = max(0,dot(normalDir,lightDir));
				float3 final_diffuse = diffuse_color*NdotL*_LightColor0.xyz;

				//模拟球形天空光 朝上的面偏白一点
				float3 sky_light = (dot(normalDir,float3(0,1,0))+1.0)*0.5;
				float3 sky_lightColor = sky_light*diffuse_color*_Opacity;

				//补色提高正面颜色
				final_diffuse = final_diffuse+_AddColor.xyz;
				//加上天光
				final_diffuse = final_diffuse+sky_lightColor;
				//透射光
				//视线方向捕捉到光 可以看到模型投射光的效果

				//扭曲打入物体内部折射方向
				float3 black_dir = -normalize(lightDir+normalDir*_Distort);

				float VDotB = max(0,dot(viewDir,black_dir));
				//限制范围 提高对比度
				float blacklight_term = max(0.0,pow(VDotB,_Power))*_Scale;

				//读取一张厚度图 用来判断投射程度
				float thickness = 1.0-tex2D(_ThicknessMap,i.uv).r;
				float3 black_term = blacklight_term*_LightColor0.xyz*thickness*_BackLightColor.xyz;

				//环境反射实现玉石表面光滑的质感 
				//光泽反射
				//旋转
				float3 reflect_dir = reflect(-viewDir,normalDir);
				half rad = _EnvRotate*UNITY_PI/180;
				float2x2 m_rot = float2x2(cos(rad),-sin(rad),sin(rad),cos(rad));
				float2 v_rot = mul(m_rot,reflect_dir.xz);
				reflect_dir = float3(v_rot.x,reflect_dir.y,v_rot.y);
				float4 hdr_color = texCUBE(_CubeMap,reflect_dir);

				//fresnel现象 NDOTV 边缘光滑一点
				float fresnel = 1.0-max(0,dot(normalDir,viewDir));

				float3 env_color = DecodeHDR(hdr_color,_CubeMap_HDR);

				float3 final_env = env_color*fresnel;

				float3 final_color = black_term+final_env+final_diffuse;
				return float4(final_color,1);
			}
			ENDCG
		}

		Pass
		{
			Tags{"LightMode"="ForwardAdd"}
			Blend One One
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			//光照计算需要增加
			#pragma multi_compile_fwdadd 
			#include "AutoLight.cginc"
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
				float4 posWorld : TEXCOORD1;
				float3 normalDir : TEXCOORD2;
				LIGHTING_COORDS(3,4)
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _LightColor0;
			float _Distort;
			float _Power;
			float _Scale;
			sampler2D _ThicknessMap;
			samplerCUBE _CubeMap;
			float4 _CubeMap_HDR;
			float _EnvRotate;
			float4 _DiffuseColor;
			float4 _AddColor;
			float _Opacity;
			float4 _BackLightColor;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord;
				o.posWorld = mul(unity_ObjectToWorld, v.vertex);
				o.normalDir = UnityObjectToWorldNormal(v.normal);
				TRANSFER_VERTEX_TO_FRAGMENT(o);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				half3 normalDir = normalize(i.normalDir);
				float3 viewDir = normalize(_WorldSpaceCameraPos-i.posWorld);
				//光源的适配
				float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
				float3 lightDir_other = normalize(_WorldSpaceLightPos0.xyz-i.posWorld);
				lightDir = lerp(lightDir,lightDir_other,_WorldSpaceLightPos0.w);

				//衰减值
				float atten = LIGHT_ATTENUATION(i);
				//漫反射 NdotL 用来提亮背面
				//float3 NdotL = max(0,dot(normal_world,light_world));
				float3 diffuse_color = _DiffuseColor.xyz;
				float3 NdotL = max(0,dot(normalDir,lightDir));
				float3 final_diffuse = diffuse_color*NdotL*_LightColor0.xyz;

				//模拟球形天空光 朝上的面偏白一点
				float3 sky_light = (dot(normalDir,float3(0,1,0))+1.0)*0.5;
				float3 sky_lightColor = sky_light*diffuse_color*_Opacity;

				//补色提高正面颜色
				final_diffuse = final_diffuse+_AddColor.xyz;
				//加上天光
				//final_diffuse = final_diffuse+sky_lightColor;
				//透射光
				//视线方向捕捉到光 可以看到模型投射光的效果

				//扭曲打入物体内部折射方向
				float3 black_dir = -normalize(lightDir+normalDir*_Distort);

				float VDotB = max(0,dot(viewDir,black_dir));
				//限制范围 提高对比度
				float blacklight_term = max(0.0,pow(VDotB,_Power))*_Scale;

				//读取一张厚度图 用来判断投射程度
				float thickness = 1.0-tex2D(_ThicknessMap,i.uv).r;
				float3 black_term = blacklight_term*_LightColor0.xyz*thickness*_BackLightColor.xyz*atten;

				//环境反射实现玉石表面光滑的质感 只需要在一个pass计算
				//光泽反射
				//旋转
				float3 reflect_dir = reflect(-viewDir,normalDir);
				half rad = _EnvRotate*UNITY_PI/180;
				float2x2 m_rot = float2x2(cos(rad),-sin(rad),sin(rad),cos(rad));
				float2 v_rot = mul(m_rot,reflect_dir.xz);
				reflect_dir = float3(v_rot.x,reflect_dir.y,v_rot.y);
				float4 hdr_color = texCUBE(_CubeMap,reflect_dir);

				//fresnel现象 NDOTV 边缘光滑一点
				float fresnel = 1.0-max(0,dot(normalDir,viewDir));

				float3 env_color = DecodeHDR(hdr_color,_CubeMap_HDR);

				float3 final_env = env_color*fresnel;

				float3 final_color = black_term+final_diffuse;
				return float4(final_color,1);
			}
			ENDCG
		}
	}
}
