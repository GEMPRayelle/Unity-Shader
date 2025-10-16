Shader "Custom/enviromental_mapping"
{
    Properties
    {
        [MainTexture] _BaseMap ("Base Map", 2D) = "White" {}
        _Cube("Reflection CubeMap", Cube) = "" {}
        _Reflectivity("Reflecivity", Range(0,1)) = 1.0
        _RimColor("Rim Color", Color) = (1,1,1,1) //Rim color
        _RimPower("Rim Power", Range(0.1, 10)) = 2 //Rim Power
    }

    SubShader
    {
        Tags 
        { 
            "RenderType"="Opaque" 
        }

        //Mesh로부터 정보를 받아오려면 Mesh Filter가 있어야함
        Pass
        {
            Tags {}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            struct appdata //Mesh로부터 받은 순수 데이터 (Attribute)
            {
                float4 vertex : POSITION; //local coordinate
                float4 texcoord : TEXCOORD0;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD1;
            };
            
            struct Interpolators
            {
                float4 position : SV_POSITION;
                float3 normal : TEXCOORD0; // local position
                float2 uv : TEXCOORD1;
                float3 positionWC: TEXCOORD2;
            };
            
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            TEXTURECUBE(_Cube);
            SAMPLER(sampler_Cube);

            float _Reflectivity;

            float3 _RimColor;
            float _RimPower;
            
            Interpolators vert (appdata input) 
            {
                Interpolators i;
                i.normal = TransformObjectToWorldNormal(input.normal); //Local Normal -> World Normal
                i.position = TransformObjectToHClip(input.vertex); //Local Coordinate -> Clip Coordinate
                i.uv = input.uv;
                return i;
            }
            
            float4 frag (Interpolators i) : SV_TARGET 
            {

                float3 N = i.normal;
                float3 V = normalize(_WorldSpaceCameraPos - i.normal);
                float3 R = reflect(-V,N);

                //Rim Light
                float power = 1 - max(0, dot(V,N));
                float fresnel = pow(power, _RimPower);
                
                //Reflection
                float3 refl = SAMPLE_TEXTURECUBE(_Cube, sampler_Cube, R).rgb;

                float3 color = lerp(float3(0,0,0), refl, _Reflectivity) + _RimColor.rgb * fresnel;
                return float4(color, 1.0);
            }
            ENDHLSL
        }
    }
}
