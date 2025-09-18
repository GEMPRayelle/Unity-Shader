Shader "Unlit/phongShader"
{
    Properties
    {
        //Property는 아래 형식을 따름
        //_Variable ("Inspector Name", Type) = default Value
        _BaseColor ("Base Color", Color) = (1,1,1,1) //default Color
        _Shininess ("Shininess", Float) = 10.0
    }
    //Phong은 가장 간단한 라이팅 모델
    //여러 가지 빛의 현상인 반사, 흡수, 산란 등 3개의 term으로 구분해서 나눔
    //Ambient, Diffuse, Specular 3개로 나눔
    //-> 4개의 벡터 2개의 Color의 정보가 필요함 (LNVR, K,I)
    //K나 I도 ambient, diffuse, specular 용으로 3개로 구분 할 수 있음
    //일반적으로 I는 따로 구분하지 않고 Id, Ia, Is로 구분함 (동일한 색상으로 사용)
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
            
            half4 _BaseColor; //Property로부터 받은 정보 (K값)
            float _Shininess;
            
            Interpolators vert (appdata input) 
            {
                Interpolators i;
                //앞으로 라이팅계산을 World 좌표계에서 할 예정
                i.normal = TransformObjectToWorldNormal(input.normal); //Local Normal -> World Normal
                i.position = TransformObjectToHClip(input.vertex); //Local Coordinate -> Clip Coordinate
                i.uv = input.uv;
                return i;
            }
            
            float4 frag (Interpolators i) : SV_TARGET 
            {
                Light mainLight = GetMainLight();
                float3 L = mainLight.direction; //World 좌표계에서 Light Vector
                float3 id = mainLight.color;
                float3 ia = mainLight.color * 0.3;
                float3 is = mainLight.color * 0.3;
                float3 kd = _BaseColor.rgb; //Property로부터 받은 K값
                float3 ka = _BaseColor.rgb;

                float3 N = i.normal;
                
                float dotLN = saturate(dot(L,N)); //값을 [0,1]사이에만 있도록 함,0보다 작으면 0, 1보다 크면 1
                //float3 V = normalize(_WorldSpaceCameraPos - i.normal);
                float3 V = normalize(GetCameraPositionWS() - i.normal);
                float3 R = reflect(-L,N);
                
                float3 ambient = ka*ia; //ambient Formula
                float3 diffuse = id*kd*dotLN; //Diffuse Formula
                float3 specular = is * pow((saturate(dot(V,R))),_Shininess);
                
                float3 phong = ambient + diffuse + specular;

                return float4(phong, 1.0);
            }
            ENDHLSL
        }
    }
}
