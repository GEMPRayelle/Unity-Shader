Shader "Unlit/triangleShader"
{
    SubShader
    {
        Tags 
        { 
            "RenderType"="Opaque" 
            "RenderPipeline" = "UniversalPipeline" 
        }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            struct appdata //Mesh로부터 받은 순수 데이터 (Attribute)
            {
                float4 vertex : POSITION; //local coordinate
                float4 color : COLOR; //Mesh's Color Attribute
            };

            struct Interpolators 
            {
                float4 position : SV_POSITION; //Clip coordinate
                float4 color : COLOR;
            };

            //vertex수 만큼 vertex Shader가 생겨서 병렬처리됨
            Interpolators vert (appdata input) 
            {
                Interpolators i;
                i.color = input.color;
                i.position = TransformObjectToHClip(input.vertex); //local 좌표계를 입력으로 넣어 -> Clip 좌표계로 변환됨
                return i;
            }
            
            //Vertex shader 처리 후 Rasterization을 통해 픽셀 정보를 넘겨줌

            //그 픽셀 정보를 fragment Shader가 받음
            float4 frag (Interpolators i) : SV_TARGET 
            {
                //R,G,B밖에 안넣었지만 barycentric을 통해 무게중심에 따라 색 보정이 이루어짐
                return i.color;
            }

            ENDHLSL
        }
    }
}
