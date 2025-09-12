//Shader Properties SubShader 등 3가지 큰 블럭으로 나뉨

Shader "R4yell3XD/NewUnlitShader"//Material에서 보여질 쉐이더 폴더와 파일 경로
{
    //인스펙터창에서 노출시킬 변수들을 선언
    //쉐이더에서 사용할 속성 값, 쉐이더 내부에서 정의를 해야 실질적으로 사용가능
    //Properties에 있는 것들은 Material에서 Color field를 여는 역할밖에 안함
    Properties
    {
        _TintColor ("Color", Color) = (1,1,1,1)//R,G,B,Alpha값
        _MainTex ("Texture", 2D) = "white" {}
    }
    //실제로 동작하는 쉐이더 코드 (실제 쉐이더 렌더링 처리가 일어나는 곳)
    //여러개의 SubShader를 작성해도됨(멀티 플랫폼에 대응하기 위함이기도 함)
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass//게임 오브젝트가 한 번 다 그려지는 과정에 대응이 됨
        {
            CGPROGRAM
            //유용한 그래픽스 라이브러리를 불러옴
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl" 
            #include "UnityCG.cginc"
            //vertex shader로서 동작할 정점을 옮기는 역할을 하는 vertex 함수
            #pragma vertext vert
            //정점에 색을 칠하는 fragment shader 로서 동작할 fragment 함수
            #pragma fragment frag

            //컬러값을 저장할 변수
            fixed4 _TintColor;
            //실제로 SubShader내에서 선언을 다시 해줘야한다
            //Properties에서 할당된 값을 변수에게 전달해줌
            //fixed4는 나열된 4개의 수를 저장할 수 있는 자료형 (ex: Vec3, Vec4)

            //vertex 함수와 fragment함수가 입력으로 받을 정점(vertex) 데이터를 구상하는 구조체 정의
            struct vertexInput{
                //정점의 오브젝트 공간상의 위치를 저장할 변수
                float3 positionOnObjectSpace : POSITION;//Semantic을 사용하여 변수의 맥락을 알려줌
                //그래픽스 API들은 Semantic을 통해서 변수의 용도를 알고 적당한 값을 해당 변수에 자동으로 채워준다
                //각 정점 데이터의 위치값이 자동으로 들어가게 됨
            }

            //vertex 쉐이더에 의한 처리가 다 끝난 상태에서 fragment로 전달될 데이터
            //vertex 쉐이더에 의해서 옮겨진 정점의 데이터를 가지고 있어야 한다
            struct vertexOutput{
                float4 positionOnClipSpace : SV_POSITION;
                //스크린에 대응되는 ClipSpace상에 위치가 저장됨 
            }
            
            //fragment 쉐이더에게 전달할 vertex함수(Vertex 쉐이더로서 동작함) 
            vertexOutput vert(vertexInput i){//입력으로 오브젝트 공간상의 정점을 받음
                //클립공간상의 정점으로 바꿔줘야 한다
                float4 positionOnClipSpace = UnityObjectToClipPos(i.positionOnObjectSpace);

                vertexOutput o;//새로운 변수를 생성(vertex 쉐이더의 출력값)
                o.positionOnClipSpace = positionOnClipSpace;
                return o;
            }

            //어떤 정점을 채울 컬러값을 리턴하는 함수
            //입력은 vertex 쉐이더를 통해 가공된 vertexOutput타입
            fixed4 frag(vertexOutput o) : SV_TARGET{//이 Semactic은 지정된 변수나 함수의 값을 Render Buffer에 쓰겠다고 선언하는 것임
                //위치값을 변환하는 처리는 따로 하지 않음 (vertex 쉐이더에서 했으니까)
                return _TintColor;//컬러값을 반환
            }

            ENDCG
        }
    }
}
