Shader "Custom/Refaction"
{
    Properties
    {
        _BaseColor("Base Color", Color) = (1,1,1,1)
        _Cube("Reflection CubeMap", Cube) = "" {}
        _RefractionIndex("Refraction Index", Range(1.0, 2.5)) = 1.5
        _FresnelPower("Fresnel Power", Range(0.1, 5.0)) = 2.0
    }

    SubShader
    {
        Tags 
        { 
            "RenderType" = "Opaque" 
            "RenderPipleline" = "UnversalRenderPipeline"
            "Queue" = "Transparent"
        }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            struct appdata //Mesh로부터 받은 순수 데이터 (Attribute)
            {
                float4 vertex : POSITION; //local coordinate
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
                float2 uv : TEXCOORD1;
            };
            
            struct Interpolators
            {
                float4 position : SV_POSITION; //Clip Position
                float3 normal : TEXCOORD0; //local position
                float2 uv : TEXCOORD1;
                float3 positionWS: TEXCOORD3; //World Position
            };
            
            TEXTURE2D(_BaseMap);
            half4 _BaseColor;
            float4 _BaseMap_ST;
            
            TEXTURECUBE(_Cube);
            SAMPLER(sampler_Cube);

            float _RefractionIndex;
            float _FresnelPower;
            
            Interpolators vert (appdata input) 
            {
                Interpolators i;
                i.normal = TransformObjectToWorldNormal(input.normal); //Local Normal -> World Normal
                i.position = TransformObjectToHClip(input.vertex); //Local Coordinate -> Clip Coordinate
                i.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                i.positionWS = TransformObjectToWorld(input.vertex);
                return i;
            }
            
            float4 frag (Interpolators i) : SV_TARGET 
            {
                float3 V = normalize(GetCameraPositionWS() - i.positionWS);
                float3 N = i.normal;
                float3 R = reflect(-V,N);
                
                //Reflection
                float3 reflectionColor = SAMPLE_TEXTURECUBE(_Cube, sampler_Cube, R).rgb;

                //Refraction
                float eta = 1.0 / _RefractionIndex; //굴절률
                float3 refractDir = refract(-V, N, eta);
                half3 refractionColor = SAMPLE_TEXTURECUBE(_Cube, sampler_Cube, refractDir).rgb;
            
                float power = 1 - max(dot(N,V), 0); 
                float f = pow(power, _FresnelPower); //Schlick's Approximation
                
                //Reflection과 Refracion의 비율을 fresnel에 따라 자동으로 조절
                float3 color = lerp(refractionColor, reflectionColor, f);

                return float4(color, 1);
            }
            ENDHLSL
        }
    }
}
