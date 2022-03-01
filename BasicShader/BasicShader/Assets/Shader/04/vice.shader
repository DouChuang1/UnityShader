// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "vice"
{
	Properties
	{
		_Cutoff( "Mask Clip Value", Float ) = 0
		_Expand("Expand", Float) = 0
		_Scale("Scale", Float) = 0
		_Grow("Grow", Range( -2 , 2)) = 0
		_GrowMin("GrowMin", Float) = 0
		_GrowMax("GrowMax", Float) = 0
		_EndMin("EndMin", Range( 0 , 1)) = 0
		_EndMax("EndMax", Range( 0 , 1.5)) = 0
		_Diffuse("Diffuse", 2D) = "white" {}
		_NormalMap("NormalMap", 2D) = "white" {}
		_Roughness("Roughness", 2D) = "white" {}
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "AlphaTest+0" "IsEmissive" = "true"  }
		Cull Back
		CGPROGRAM
		#pragma target 3.0
		#pragma surface surf Standard keepalpha addshadow fullforwardshadows vertex:vertexDataFunc 
		struct Input
		{
			float2 uv_texcoord;
		};

		uniform float _GrowMin;
		uniform float _GrowMax;
		uniform float _Grow;
		uniform float _EndMin;
		uniform float _EndMax;
		uniform float _Expand;
		uniform float _Scale;
		uniform sampler2D _NormalMap;
		uniform float4 _NormalMap_ST;
		uniform sampler2D _Diffuse;
		uniform float4 _Diffuse_ST;
		uniform sampler2D _Roughness;
		uniform float4 _Roughness_ST;
		uniform float _Cutoff = 0;

		void vertexDataFunc( inout appdata_full v, out Input o )
		{
			UNITY_INITIALIZE_OUTPUT( Input, o );
			float temp_output_7_0 = ( v.texcoord.xy.y - _Grow );
			float smoothstepResult9 = smoothstep( _GrowMin , _GrowMax , temp_output_7_0);
			float smoothstepResult13 = smoothstep( _EndMin , _EndMax , v.texcoord.xy.y);
			float3 ase_vertexNormal = v.normal.xyz;
			v.vertex.xyz += ( ( max( smoothstepResult9 , smoothstepResult13 ) * ase_vertexNormal * _Expand * 0.1 ) + ( ase_vertexNormal * 0.01 * _Scale ) );
			v.vertex.w = 1;
		}

		void surf( Input i , inout SurfaceOutputStandard o )
		{
			float2 uv_NormalMap = i.uv_texcoord * _NormalMap_ST.xy + _NormalMap_ST.zw;
			o.Normal = tex2D( _NormalMap, uv_NormalMap ).rgb;
			float2 uv_Diffuse = i.uv_texcoord * _Diffuse_ST.xy + _Diffuse_ST.zw;
			o.Emission = tex2D( _Diffuse, uv_Diffuse ).rgb;
			float2 uv_Roughness = i.uv_texcoord * _Roughness_ST.xy + _Roughness_ST.zw;
			o.Smoothness = ( 1.0 - tex2D( _Roughness, uv_Roughness ) ).r;
			o.Alpha = 1;
			float temp_output_7_0 = ( i.uv_texcoord.y - _Grow );
			clip( ( 1.0 - temp_output_7_0 ) - _Cutoff );
		}

		ENDCG
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=18500
7;29;1906;1014;1347.848;528.4657;1.3;True;True
Node;AmplifyShaderEditor.TextureCoordinatesNode;5;-816.1996,-167.4999;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;6;-815.1996,-13.50001;Inherit;False;Property;_Grow;Grow;3;0;Create;True;0;0;False;0;False;0;0.56;-2;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;14;-840,396;Inherit;False;Property;_EndMin;EndMin;6;0;Create;True;0;0;False;0;False;0;0.603;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;7;-498.1996,-139.4999;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;10;-478.1996,-16.50001;Inherit;False;Property;_GrowMin;GrowMin;4;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;11;-480.1996,75.49999;Inherit;False;Property;_GrowMax;GrowMax;5;0;Create;True;0;0;False;0;False;0;1.267;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;12;-812,236;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;15;-815,476;Inherit;False;Property;_EndMax;EndMax;7;0;Create;True;0;0;False;0;False;0;1.154;0;1.5;0;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;13;-545.223,300.3737;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;9;-266.2,9.500002;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.NormalVertexDataNode;1;-301,351;Inherit;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMaxOpNode;16;-298,167;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;18;30.15155,527.1348;Inherit;False;Property;_Scale;Scale;2;0;Create;True;0;0;False;0;False;0;3;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;19;27.55156,637.6342;Inherit;False;Constant;_Float1;Float 0;1;0;Create;True;0;0;False;0;False;0.01;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;3;-283.4998,526.4003;Inherit;False;Constant;_Float0;Float 0;1;0;Create;True;0;0;False;0;False;0.1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;2;-302.7999,646.0999;Inherit;False;Property;_Expand;Expand;1;0;Create;True;0;0;False;0;False;0;-3.63;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.NormalVertexDataNode;17;6.751612,356.8343;Inherit;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;24;243.352,-453.0656;Inherit;True;Property;_Roughness;Roughness;10;0;Create;True;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;20;264.1517,446.5343;Inherit;False;3;3;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;4;-42,132;Inherit;False;4;4;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;23;-86.84809,-456.9656;Inherit;True;Property;_NormalMap;NormalMap;9;0;Create;True;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;22;-478.148,-450.4655;Inherit;True;Property;_Diffuse;Diffuse;8;0;Create;True;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.OneMinusNode;8;-198.2001,-127.4999;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;21;291.4515,358.1343;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.OneMinusNode;25;343.4519,-234.6657;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;480.4191,-118.6065;Float;False;True;-1;2;ASEMaterialInspector;0;0;Standard;vice;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Custom;0;True;True;0;True;Opaque;;AlphaTest;All;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;0;0;False;-1;0;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;0;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;False;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;7;0;5;2
WireConnection;7;1;6;0
WireConnection;13;0;12;2
WireConnection;13;1;14;0
WireConnection;13;2;15;0
WireConnection;9;0;7;0
WireConnection;9;1;10;0
WireConnection;9;2;11;0
WireConnection;16;0;9;0
WireConnection;16;1;13;0
WireConnection;20;0;17;0
WireConnection;20;1;19;0
WireConnection;20;2;18;0
WireConnection;4;0;16;0
WireConnection;4;1;1;0
WireConnection;4;2;2;0
WireConnection;4;3;3;0
WireConnection;8;0;7;0
WireConnection;21;0;4;0
WireConnection;21;1;20;0
WireConnection;25;0;24;0
WireConnection;0;1;23;0
WireConnection;0;2;22;0
WireConnection;0;4;25;0
WireConnection;0;10;8;0
WireConnection;0;11;21;0
ASEEND*/
//CHKSM=6B2EE2E484DB8F129BC47E41C8EEFE985F95CB6C