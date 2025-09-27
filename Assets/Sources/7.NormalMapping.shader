Shader "Unlit/normal_mapping_blinn"
{
    Properties
    {
        [MainTexture] _BaseMap ("Base Map", 2D) = "White" {}
        _NormalMap("Normal Map", 2D) = "bump" {}
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
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangentOS : TANGENT; //Local tangent임
            };
            
            //vert에서 frag로 넘기기위한 값들
            struct Interpolators
            {
                float4 position : SV_POSITION;
                float2 uv : TEXCOORD0; // local uv
                float3 positionWS : TEXCOORD1; //world 공간에서의 position
                float3 normalWS: TEXCOORD2; //world 공간에서의 normal
                float3 T : TEXCOORD3;
                float3 B : TEXCOORD4;
                float3 N : TEXCOORD5;
            };
            
            half4 _BaseColor; //Property로부터 받은 정보 (K값)
            float _Shininess;
            
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);
            float4 _BaseMap_ST;

            TEXTURE2D(_NormalMap);
            SAMPLER(sampler_NormalMap);
            float4 _NormalMap_ST;
            
            Interpolators vert (appdata input) 
            {
                Interpolators i;
                half tangentSign = input.tangentOS.w;

                float3 N = TransformObjectToWorldNormal(input.normal); //Local Normal -> World Normal
                float3 T = normalize(TransformObjectToWorldDir(input.tangentOS.xyz));//Local tangent -> World Tangent
                float3 B = cross(N, T) * tangentSign;

                i.position = TransformObjectToHClip(input.vertex);
                i.positionWS = TransformObjectToHClip(input.vertex); //Local Coordinate -> Clip Coordinate
                i.uv = input.uv;
                i.normalWS = N;

                i.N = N;
                i.T = T;
                i.B = B;

                return i;
            }
            
            float4 frag (Interpolators i) : SV_TARGET 
            {
                //UnpackNormal에서 normal.z가 두드러짐을 나타냄 (러프함)
                half3 tnormal =  UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, i.uv));
                float3x3 TBN = float3x3(i.T, i.B, i.N);
                float4 albedo = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);

                Light mainLight = GetMainLight();
                Light secondLight = GetAdditionalLight(0,i.positionWS);

                float3 kd = _BaseColor.rgb; //Property로부터 받은 K값
                float3 ka = _BaseColor.rgb;

                float3 L = mainLight.direction; //World 좌표계에서 Light Vector
                float3 id = mainLight.color;
                float3 ia = mainLight.color * 0.3;
                float3 is = mainLight.color * 0.3;

                float3 L2 = secondLight.direction;
                float3 i2d = secondLight.color;
                float3 i2a = secondLight.color * 0.3;
                float3 i2s = secondLight.color * 0.3;

                //N을 노말맵에서 받아온다음 Tangent Space로 바꿔서 사용함
                half3 N = normalize(mul(tnormal,TBN)); //N을 tangent space로 변경
                //float3 N = i.normal;
                
                float dotLN = saturate(dot(L,N)); //값을 [0,1]사이에만 있도록 함,0보다 작으면 0, 1보다 크면 1
                float dotLN2 = saturate(dot(L2,N)); 

                float3 V = normalize(GetCameraPositionWS() - i.positionWS);
                //float3 V = normalize(_WorldSpaceCameraPos - i.normal);
                float3 R = reflect(-L,N);

                float3 H = normalize(L2+V); //blinn-Phong Half Vector
                
                float2 uv = TRANSFORM_TEX(i.uv, _BaseMap);
                float4 texColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);

                float3 ambient = ka*ia; //ambient Formula
                float3 diffuse = id*kd*dotLN; //Diffuse Formula
                float3 specular = is * pow((saturate(dot(V,R))),_Shininess);
                float3 phong = (ambient + diffuse) * (albedo.xyz) + specular ;

                float3 ambient2 = kd*i2a; //ambient Formula
                float3 diffuse2 = kd*i2d*dotLN2; //Diffuse Formula
                float3 specular2 = i2s * pow((saturate(dot(N, H))),_Shininess);
                float3 phong2 = ambient2 + diffuse2 + specular2;

                return float4(phong + phong2, 1.0);
            }
            ENDHLSL
        }
    }
}
