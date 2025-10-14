Shader "Unlit/Sprite_Shader_billboard"
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
            "RenderPipleline" = "UnversalRenderPipeline"
            "Queue" = "AlphaTest"
            "IgnoreProjector" = "True"
        }

        ZWrite On //AlphaTest시 ZWrite 활성화 해야 함
        Blend SrcAlpha OneMinusSrcAlpha //프레임버퍼에 들어 있는 값과 새로운 값을 어떻게 블랜딩하나

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing //Use GPU Instancing
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            struct appdata //Mesh로부터 받은 순수 데이터 (Attribute)
            {
                float4 vertex : POSITION; //local coordinate
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
                float2 uv : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            struct Interpolators
            {
                float4 position : SV_POSITION;
                float3 normal : TEXCOORD0; // local position
                float2 uv : TEXCOORD1;
                float3 positionWC: TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            half4 _BaseColor; //Property로부터 받은 정보 (K값)
            SAMPLER(sampler_MainTex);
            sampler2D _MainTex;

            float _Cutoff;
            float4 _MainTex_ST;
            
            Interpolators vert (appdata input) 
            {
                Interpolators i;
                
                i.normal = TransformObjectToWorldNormal(input.normal);
                i.uv = TRANSFORM_TEX(input.uv, _MainTex);
                i.positionWC = TransformObjectToWorld(input.vertex);

                UNITY_SETUP_INSTANCE_ID(input);

                //Unity View 행렬
                float3 _r = UNITY_MATRIX_V[0].xyz; //1st column
                float3 _u = UNITY_MATRIX_V[1].xyz; //2nd column
                float3 _f = UNITY_MATRIX_V[2].xyz; //3rd column

                //q는 Quad의 중심점
                // 인스턴스의 월드 위치 (GPU 인스턴싱 대응)
                float3 q = mul(UNITY_MATRIX_M, float4(0,0,0,1)).xyz;

                float4x4 B = {
                    _r.x, _u.x, _f.x, q.x,
                    _r.y, _u.y, _f.y, q.y,
                    _r.z, _u.z, _f.z, q.z,
                    0, 0, 0, 1
                };

                float3 s = float3(
                    length(UNITY_MATRIX_M._m00_m10_m20),
                    length(UNITY_MATRIX_M._m01_m11_m21),
                    length(UNITY_MATRIX_M._m02_m12_m22)
                );

                float3 scaledVertex = input.vertex.xyz * s;
                float3 vertex = mul(B, float4(scaledVertex, 1.0)).xyz;
                vertex.x += sin(vertex.z * 4.0 + _Time.y * 2.0) * 0.2;
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
