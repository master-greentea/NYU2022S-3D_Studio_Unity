using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class CameraRay : MonoBehaviour
{
    [SerializeField]
    private Volume postProcessV;
    private DepthOfField dof;

    RaycastHit hit;
    // Start is called before the first frame update
    void Start()
    {
        postProcessV.profile.TryGet<DepthOfField>(out dof);
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    void FixedUpdate()
    {
        if (Physics.Raycast(transform.position, transform.TransformDirection(Vector3.forward), out hit, Mathf.Infinity))
        {
            Debug.DrawRay(transform.position, transform.TransformDirection(Vector3.forward) * hit.distance, Color.green);
            if (hit.distance > 10) {
                dof.focusDistance.value = Mathf.Lerp(dof.focusDistance.value, 15f, Time.deltaTime);
            }
            else dof.focusDistance.value = Mathf.Lerp(dof.focusDistance.value, 1.5f, Time.deltaTime * 2.5f);
            // dof.focusDistance.value = hit.distance;
            Debug.Log(dof.focusDistance.value);
        }
        else
        {
            Debug.DrawRay(transform.position, transform.TransformDirection(Vector3.forward) * 1000, Color.white);
            dof.focusDistance.value = Mathf.Lerp(dof.focusDistance.value, 30f, Time.deltaTime);
        }
    }
}
