Shader "lit/Phong"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_NormalMap ("Normap", 2D) = "bump" {}
		_Ambient("Ambient",Color)=(1,1,1,1)
		_Shininess("Shininess",Range(0,64))=4
		_SpecIntensity("SpecIntensity",Range(0.1,5))=1
		_AOMap ("AOMap", 2D) = "white" {}
		_SpecMask("SpecMask", 2D) = "white" {}
		_NormalIntensity("NormalIntensity",Range(0.1,5))=1
		_ParallaxMap("ParallaxMap",2D)="white" {}
		_Parallax("Parallax",Float) = 1
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100
		//前向渲染需要 两个pass 一个是ForwardBase 一个是ForwardAdd
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
				float4 tangent:TANGENT;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 pos : SV_POSITION;
				float3 normal_world : TEXCOORD1;
				float3 pos_world: TEXCOORD2;
				float3 tangent_world : TEXCOORD3;
				float3 binormal_world : TEXCOORD4;
				SHADOW_COORDS(5)
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _LightColor0; //需要定义
			float _Shininess;
			half4 _Ambient;
			float _SpecIntensity;
			sampler2D _AOMap;
			sampler2D _SpecMask;
			sampler2D _NormalMap;
			float _NormalIntensity;
			float _Parallax;
			sampler2D _ParallaxMap;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.normal_world = normalize(mul(float4(v.normal,0),unity_WorldToObject).xyz);
				o.pos_world = mul(unity_ObjectToWorld,v.vertex).xyz;
				o.tangent_world = normalize(mul(unity_ObjectToWorld,float4(v.tangent.xyz,0)).xyz);  //世界空间顶点切线
				o.binormal_world = normalize(cross(o.normal_world,o.tangent_world))*v.tangent.w; //最后的乘法是用来处理不同平台下 次法线的反转问题
				TRANSFER_SHADOW(o)
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				//模型细节优化：置换贴图 将模型变为高模，性能消耗比较大
				//这里使用视差贴图的技术，通过变换看到的uv得到细节更丰富的表面 
				half3 normal_world = normalize(i.normal_world);
				half3 tangent_world = normalize(i.tangent_world);
				half3 binormal_world = normalize(i.binormal_world);
				float3 view_world = normalize(_WorldSpaceCameraPos.xyz-i.pos_world);
				float3x3 TBN = float3x3(tangent_world,binormal_world,normal_world);
				//观察坐标转为切线空间
				half3 view_tangent = normalize(mul(TBN,view_world));
				half2 uv_parallax = i.uv;  //视差初始化uv
				//循环 消耗性能 谨慎使用
				for(int j=0;j<10;j++)
				{
					half height = tex2D(_ParallaxMap,uv_parallax);
					uv_parallax = uv_parallax-(1.0-height)*view_tangent.xy*_Parallax*0.01f;
				}

				// sample the texture
				fixed4 base_col = tex2D(_MainTex, uv_parallax);  //基本颜色
				fixed4 ao_col = tex2D(_AOMap,uv_parallax);   //用来丰富最终颜色
				fixed4 specmask_col = tex2D(_SpecMask,uv_parallax);

				//法线贴图
				half4 normalMap = tex2D(_NormalMap,uv_parallax);
				half3 normal_data = UnpackNormal(normalMap);

				//使用法线贴图之后法线重计算 完善细节
				//float3x3 TBN = float3x3(tangent_world,binormal_world,normal_world);
				//normal_world = normalize(mul(normal_data.xyz,TBN));
				normal_world = normalize(tangent_world*normal_data.x+binormal_world*normal_data.y*_NormalIntensity+normal_world*normal_data.z);

				//计算阴影
				half shadow = SHADOW_ATTENUATION(i);

				//漫反射
				float3 light_world = normalize(_WorldSpaceLightPos0.xyz);
				half diff_trem=min(shadow, max(0,dot(normal_world,light_world)));
				float3 diffuse_color = diff_trem*_LightColor0.xyz*base_col.xyz;

				//高光
				half3 reflect_dir = reflect(-light_world,normal_world);
				half RdotV = dot(reflect_dir,view_world);
				half3 spec_color = pow(max(0,RdotV),_Shininess)*_LightColor0.xyz*_SpecIntensity*specmask_col.xyz*diff_trem;

				//环境光
				half3 ambient_color = _Ambient.xyz;

				half3 final_color = (diffuse_color+spec_color+ambient_color)*ao_col.xyz;
			
			    //高光优化 ：显示器显示的是0-1之间 但是返回的颜色值是任意的 导致显示屏幕会丢失很多细节
				//shader返回的数据属于HDR
				//屏幕对应的是LDR
				//tone-mapping 在LDR模拟HDR 亮度重映射
				//shader中一般不使用这个技术 一般放在屏幕后处理中 这里知道有这个技术就可以

				
				return float4(final_color,1);
			}
			ENDCG
		}

		Pass
		{
			Blend One One
			Tags{"LightMode"="ForwardAdd"}
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
				float4 tangent:TANGENT;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 pos : SV_POSITION;
				float3 normal_world : TEXCOORD1;
				float3 pos_world: TEXCOORD2;
				float3 tangent_world : TEXCOORD3;
				float3 binormal_world : TEXCOORD4;
				SHADOW_COORDS(5)
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _LightColor0; //需要定义
			float _Shininess;
			half4 _Ambient;
			float _SpecIntensity;
			sampler2D _AOMap;
			sampler2D _SpecMask;
			sampler2D _NormalMap;
			float _NormalIntensity;
			float _Parallax;
			sampler2D _ParallaxMap;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.normal_world = normalize(mul(float4(v.normal,0),unity_WorldToObject).xyz);
				o.pos_world = mul(unity_ObjectToWorld,v.vertex).xyz;
				o.tangent_world = normalize(mul(unity_ObjectToWorld,float4(v.tangent.xyz,0)).xyz);  //世界空间顶点切线
				o.binormal_world = normalize(cross(o.normal_world,o.tangent_world))*v.tangent.w; //最后的乘法是用来处理不同平台下 次法线的反转问题
				TRANSFER_SHADOW(o)
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				//模型细节优化：置换贴图 将模型变为高模，性能消耗比较大
				//这里使用视差贴图的技术，通过变换看到的uv得到细节更丰富的表面 
				half3 normal_world = normalize(i.normal_world);
				half3 tangent_world = normalize(i.tangent_world);
				half3 binormal_world = normalize(i.binormal_world);
				float3 view_world = normalize(_WorldSpaceCameraPos.xyz-i.pos_world);
				float3x3 TBN = float3x3(tangent_world,binormal_world,normal_world);
				//观察坐标转为切线空间
				half3 view_tangent = normalize(mul(TBN,view_world));
				half2 uv_parallax = i.uv;  //视差初始化uv
				//循环 消耗性能 谨慎使用
				for(int j=0;j<10;j++)
				{
					half height = tex2D(_ParallaxMap,uv_parallax);
					uv_parallax = uv_parallax-(1.0-height)*view_tangent.xy*_Parallax*0.01f;
				}

				// sample the texture
				fixed4 base_col = tex2D(_MainTex, uv_parallax);  //基本颜色
				fixed4 ao_col = tex2D(_AOMap,uv_parallax);   //用来丰富最终颜色
				fixed4 specmask_col = tex2D(_SpecMask,uv_parallax);

				//法线贴图
				half4 normalMap = tex2D(_NormalMap,uv_parallax);
				half3 normal_data = UnpackNormal(normalMap);

				//使用法线贴图之后法线重计算 完善细节
				//float3x3 TBN = float3x3(tangent_world,binormal_world,normal_world);
				//normal_world = normalize(mul(normal_data.xyz,TBN));
				normal_world = normalize(tangent_world*normal_data.x+binormal_world*normal_data.y*_NormalIntensity+normal_world*normal_data.z);

				//计算阴影
				half shadow = SHADOW_ATTENUATION(i);

				float3 light_world = normalize(_WorldSpaceLightPos0.xyz);
				half attuenation = 1.0;

				#if defined (DIRECTIONAL)
					light_world = normalize(_WorldSpaceLightPos0.xyz);
				#elif defined (POINT)
					light_world = normalize(_WorldSpaceLightPos0.xyz-i.pos_world);
					half distance = length(_WorldSpaceLightPos0.xyz-i.pos_world);
					half range = 1.0/unity_WorldToLight[0][0];
					attuenation = saturate((range-distance)/range);
				#endif
				//漫反射
				half diff_trem=min(shadow, max(0,dot(normal_world,light_world)));
				float3 diffuse_color = diff_trem*_LightColor0.xyz*base_col.xyz*attuenation;

				//高光
				half3 reflect_dir = reflect(-light_world,normal_world);
				half RdotV = dot(reflect_dir,view_world);
				half3 spec_color = pow(max(0,RdotV),_Shininess)*_LightColor0.xyz*_SpecIntensity*specmask_col.xyz*diff_trem*attuenation;

				half3 final_color = (diffuse_color+spec_color)*ao_col.xyz;
			
			    //高光优化 ：显示器显示的是0-1之间 但是返回的颜色值是任意的 导致显示屏幕会丢失很多细节
				//shader返回的数据属于HDR
				//屏幕对应的是LDR
				//tone-mapping 在LDR模拟HDR 亮度重映射
				//shader中一般不使用这个技术 一般放在屏幕后处理中 这里知道有这个技术就可以

				
				return float4(final_color,1);
			}
			ENDCG
		}
	
	}
	FallBack "Diffuse"  //增加一个 shadowcaster的pass
}
