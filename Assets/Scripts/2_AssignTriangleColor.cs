using UnityEngine;

[RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
public class AssignTriangleColors : MonoBehaviour
{
    private void Start()
    {
        Mesh mesh = GetComponent<MeshFilter>().mesh; //mesh정보를 받아옴
        if (mesh.vertexCount >= 3)
        {
            //각 Vertex마다 색상 정보를 기입
            Color[] colors = new Color[mesh.vertexCount];

            colors[0] = Color.red;
            colors[1] = Color.green;
            colors[2] = Color.blue;

            mesh.colors = colors;
        }
    }
}
