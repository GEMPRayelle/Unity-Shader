Shader "Unlit/texture_mapping"
{
    Properties
    {
        //인스펙터에서 텍스처를 받을 프로퍼티
        [MainTexture] _BaseMap ("Base Map", 2D) = "White" {} //_MainTex로 선언해도 됨
        _BaseColor ("Base Color", Color) = (1,1,1,1) //default Color
        _Shininess ("Shininess", Float) = 10.0 //phong shininess
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
            
            half4 _BaseColor; //Property로부터 받은 정보 (K값)
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            float4 _BaseMap_ST; //Offset 정보가 들어있음
            float _Shininess;
            
            Interpolators vert (appdata input) 
            {
                Interpolators i;
                i.normal = TransformObjectToWorldNormal(input.normal); //Local Normal -> World Normal
                i.position = TransformObjectToHClip(input.vertex); //Local Coordinate -> Clip Coordinate
                
                /*Texture Scrolling*/
                //i.uv = input.uv;
                i.uv = TRANSFORM_TEX(input.uv, _BaseMap); //_BaseMap_ST가 반드시 필요함
                i.uv.x += _Time.x;
                
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
                float3 V = normalize(GetCameraPositionWS() - i.normal);
                //float3 V = normalize(_WorldSpaceCameraPos - i.normal);
                float3 R = reflect(-L,N);
                
                float3 ambient = ka*ia; //ambient Formula
                float3 diffuse = id*kd*dotLN; //Diffuse Formula
                float3 specular = is * pow((saturate(dot(V,R))),_Shininess);

                float2 uv = TRANSFORM_TEX(i.uv, _BaseMap);
                float4 texColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);

                float3 phong = (ambient + diffuse) * (texColor.xyz) + specular ;

                return float4(phong, 1.0);
            }
            ENDHLSL
        }
    }
}
