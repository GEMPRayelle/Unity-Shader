Shader "Unlit/Sprite_Shader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BaseColor ("Base Color", Color) = (1,1,1,1)
        _Cutoff ("Alpha Cutoff", Range(0,1)) = 0.5 //Sprite의 백그라운드, 포그라운드 구분 알파값
    }
    SubShader
    {
        Tags 
        {     
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalRenderPipeline"
            "Queue" = "AlphaTest"
            "IgnoreProjector" = "True" 
        }

        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha //프레임버퍼에 들어 있는 값과 새로운 값을 어떻게 블랜딩하나

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }

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
            
            half4 _BaseColor; //Property로부터 받은 정보 (K값)
            SAMPLER(sampler_MainTex);
            sampler2D _MainTex;

            float _Cutoff;
            float _Shininess;
            float4 _MainTex_ST;
            
            Interpolators vert (appdata input) 
            {
                Interpolators i;
                i.normal = TransformObjectToWorldNormal(input.normal);
                i.uv = TRANSFORM_TEX(input.uv, _MainTex);
                i.positionWC = TransformObjectToWorld(input.vertex);

                //Unity View 행렬
                float3 _r = UNITY_MATRIX_V[0].xyz; //1st column
                float3 _u = UNITY_MATRIX_V[1].xyz; //2nd column
                float3 _f = UNITY_MATRIX_V[2].xyz; //3rd column

                //q는 Quad의 중심점
                float3 q = TransformObjectToWorld(float3(0,0,0)); //local->world로 변경

                float4x4 B = {
                    _r.x, _u.x, _f.x, q.x,
                    _r.y, _u.y, _f.y, q.y,
                    _r.z, _u.z, _f.z, q.z,
                    0, 0, 0, 1
                };

                float3 s = unity_ObjectToWorld._m00_m11_m22;

                float3 scaledVertex = input.vertex.xyz * float3(s.x, s.y, s.z);
                float3 vertex = mul(B, float4(scaledVertex, 1.0)).xyz;
                i.position = TransformWorldToHClip(vertex);   

                return i;
            }
            
            float4 frag (Interpolators i) : SV_TARGET 
            {
                half4 base = tex2D(_MainTex, i.uv);
                clip(base.a - _Cutoff);

                return base * _BaseColor;
            }
            
            ENDHLSL
        }
    }
}
