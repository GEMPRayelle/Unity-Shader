Shader "Unlit/myShader"
{
    Properties{} //텍스처나 필요한 데이터들을 인스펙터에서 받아옴
    SubShader
    {
        Tags //쉐이더의 목적을 결정하는 프로퍼티를 작성함
        {
            //subshader tags :key -value 페어를 이용
            "RenderType" = "Opaque" //속이 꽉차고 안이 투명하지 않은 물체를 렌더링
            "RenderPipeline" = "UniversalPipeline"
        }
        
        Pass //SubShader안에 보통 Pass 2개 이상은 잘 안씀
        {
            Tags { }
            HLSLPROGRAM //built-in-RP면 CGPROGRAM

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" //기본 함수 제공

            //Shader Code here
            #pragma vertex vert //Vertex Shader를 vert로 정의
            #pragma fragment frag //fragment Shader를 frag로 정의

            //color를 나타낼때는 half정도면 충분함 (0~255)
            //HLSL에서 행렬은 row column순서로 접근함 (row 단위임)

            //GLSL이랑 달리 mul 함수를 써야 곱하기가 가능함 mul(M,v)

            //1. 광원은 없다고 가정하고 노말을 사용해서 노말을 컬러로 바꿔서 색자체를 출력하는것
            struct appdata_base
            {
                //Sementic 방법(데이터의 속성(특징)을 나타내는 키워드)
                //vertex는 로컬좌표계라고 지정함
                float4 vertex : POSITION; //local coordinate, 동차좌표계땜에 float4를 사용
                float3 normal : NORMAL; //노말 값
                float2 uv : TEXCOORD0; //uv는 texture 좌표계라고 지정함 (uv coordinate)
            };

            //normal Mapping에 사용할때 사용
            struct appdata_tan { 
                float4 vertex : POSITION;
                float4 tangent : TANGENT;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
            };

            //Mesh데이터의 모든걸 받아올때 full구조체 사용
            struct appdata_full{
                float4 vertex : POSITION;
                float4 tangent : TANGENT;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0; 
                float4 texcoord1 : TEXCOORD1; 
                float4 texcoord2 : TEXCOORD2; 
                float4 texcoord3 : TEXCOORD3;
            #if defined(SHADER_API_XBOX360) 
                half4 texcoord4 : TEXCOORD4; 
                half4 texcoord5 : TEXCOORD5;
            #endif
                fixed4 color : COLOR;
            }

            //vertex에서 frag로 값을 넘길때 중간다리역할
            //vertex에 대해서만 계산한거지 그 안에 픽셀을 계산은 안한 상태임
            //fragment는 rasterization을 끝난 후에 수행되므로 
            //픽셀 정보를 보간하는 역할을 함
            struct Interpolators {
                float4 position : SV_POSITION; //gl_position에 해당하는것 (mvp곱하는거, Clip 좌표계로 변환된 값)
                float3 normal : TEXCOORD0;
            };

            //Vertex shader에서 Mesh 데이터를 받는 방법
            Interpolators vert(appdata_base input) 
            {
                Interpolators i; 
                i.normal = (input.normal + 1.0)*0.5; //[-1,1]까지인 normal을 컬러로 사용하기 위해 [0,1]로 변환시킴
                i.position = TransformObjectToHClip(input.vertex); //local에서 clip 좌표계로 변환
                return i; //fragment shader로 데이터를 넘김
            }

            //SV_Target = 4차원 벡터의 Color를 리턴한다는 의미
            float4 frag(Interpolators i) : SV_TARGET // = out vec4 FragColor
            {
                return float4(i.normal,1); //normal의 색상을 이용
            }
            ENDHLSL
        }
        Pass { } //Optimal
    }
}
