using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FollowHeadY : MonoBehaviour
{
    [SerializeField]
    Transform head;

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        transform.position = new Vector3(transform.position.x, head.position.y, transform.position.z);
    }
}
