Shader "Unlit/parallax_mapping"
{
    Properties
    {
        [MainTexture] _BaseMap ("Base Map", 2D) = "White" {}
        _NormalMap("Normal Map", 2D) = "bump" {}
        _HeightMap("Height Map", 2D) = "white" {}
        _HeightScale("Height Scale", Range(0,0.1)) = 0.0 //Height map Scale

        _BaseColor ("Base Color", Color) = (1,1,1,1) //default Color
        _Shininess ("Shininess", Range(0,1)) = 10.0 //phong shininess
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" }

        //Mesh로부터 정보를 받아오려면 Mesh Filter가 있어야함
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
                float4 tangentOS : TANGENT; //Local tangent임
                float2 uv : TEXCOORD0;
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
            float _HeightScale;
            
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);
            float4 _BaseMap_ST;

            TEXTURE2D(_NormalMap);
            SAMPLER(sampler_NormalMap);
            float4 _NormalMap_ST;

            TEXTURE2D(_HeightMap);
            SAMPLER(sampler_HeightMap);
            float4 _HeightMap_ST;


            //A점의 uv, viewDirTS = tangent Space에서의 V vector
            float2 ParallaxOffset(float2 uv, float3 viewDirTS)
            {
                float height = SAMPLE_TEXTURE2D(_HeightMap, sampler_HeightMap, uv).r;
                float2 offset = viewDirTS.xy / viewDirTS.z * (height * (_HeightScale));
                return uv - offset;
            }
            
            Interpolators vert (appdata input) 
            {
                Interpolators i;
                i.position = TransformObjectToHClip(input.vertex);
                i.uv = input.uv;

                half tangentSign = input.tangentOS.w;

                float3 N = TransformObjectToWorldNormal(input.normal); //Local Normal -> World Normal
                float3 T = normalize(TransformObjectToWorldDir(input.tangentOS.xyz));//Local tangent -> World Tangent
                float3 B = cross(N, T) * tangentSign;

                i.N = N;
                i.T = T;
                i.B = B;

                /*추가된 코드*/
                float3 worldPos = TransformObjectToWorld(input.vertex).xyz;
                float3 viewDirWS = normalize(GetCameraPositionWS() - worldPos);
                float3x3 TBN = float3x3(T,B,N);
                i.positionWS = mul(TBN, viewDirWS);

                //i.positionWS = TransformObjectToHClip(input.vertex); //Local Coordinate -> Clip Coordinate
                i.positionWS = TransformObjectToWorld(input.vertex.xyz);
                //i.normalWS = N;

                /*추가된 코드*/
                Light mainLight = GetMainLight();
                float3 lightDirWS = normalize(mainLight.direction);
                i.normalWS = mul(TBN, lightDirWS);

                return i;
            }
            
            float4 frag (Interpolators i) : SV_TARGET 
            {
                float3x3 TBN = float3x3(i.T, i.B, i.N);

                float3 viewDirWS = GetWorldSpaceNormalizeViewDir(i.positionWS);
                float3 viewDirTS = mul(TBN, viewDirWS); // World → Tangent 변환

                float2 uvP = ParallaxOffset(i.uv, viewDirTS); //uvP 조정된 UV

                //Normal Mapping
                half3 normalTS = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uvP));
                half3 N = normalize(mul(TBN, normalTS)); //N을 노말맵에서 받아온다음 Tangent Space로 바꿔서 사용함

                float3 kd = _BaseColor.rgb; //Property로부터 받은 K값
                float3 ka = _BaseColor.rgb * 0.1;

                //Lighting
                Light mainLight = GetMainLight();
                float3 L = mainLight.direction; //World 좌표계에서 Light Vector
                float3 id = mainLight.color;
                float3 ia = mainLight.color * 0.3;
                float3 is = mainLight.color * 0.3;
                
                float dotLN = saturate(dot(L,N)); //값을 [0,1]사이에만 있도록 함,0보다 작으면 0, 1보다 크면 1
                //float dotLN = max(0.0, dot(N,L));

                float3 V = normalize(GetCameraPositionWS() - i.positionWS);
                float3 R = reflect(-L,N);

                float3 texColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uvP).rgb;

                //Ambient, Diffuse, Specular
                float3 ambient = ka*ia; //ambient Formula
                float3 diffuse = id*kd*dotLN; //Diffuse Formula
                float3 specular = is * pow((saturate(dot(V,R))),_Shininess); //Specular Formula
                float3 phong = texColor * (ambient + diffuse) + specular ;

                return float4(phong, 1.0);
            }
            ENDHLSL
        }
    }
}
