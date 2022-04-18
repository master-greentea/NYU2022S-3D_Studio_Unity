using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class CameraRay : MonoBehaviour
{
    [SerializeField] private Volume postProcessV;
    private DepthOfField dof;

    [SerializeField] private Light flashlight;
    private float startIntensity;

    RaycastHit hit;

    void Start()
    {
        postProcessV.profile.TryGet<DepthOfField>(out dof);
        startIntensity = flashlight.intensity;
    }

    void FixedUpdate()
    {
        if (Physics.Raycast(transform.position, transform.TransformDirection(Vector3.forward), out hit, Mathf.Infinity))
        {
            Debug.DrawRay(transform.position, transform.TransformDirection(Vector3.forward) * hit.distance, Color.green);

            // light intensity
            if (hit.distance < 1) {
                flashlight.intensity = Mathf.Lerp(flashlight.intensity, 1.75f, Time.deltaTime * 1.5f);
            }
            else flashlight.intensity = Mathf.Lerp(flashlight.intensity, startIntensity, Time.deltaTime * 2f);

            // dof change
            if (hit.distance > 10) {
                dof.focusDistance.value = Mathf.Lerp(dof.focusDistance.value, 15f, Time.deltaTime);
            }
            else dof.focusDistance.value = Mathf.Lerp(dof.focusDistance.value, 1.5f, Time.deltaTime * 2.5f);

            // Debug.Log(dof.focusDistance.value);
        }
        else
        {
            Debug.DrawRay(transform.position, transform.TransformDirection(Vector3.forward) * 1000, Color.white);
            dof.focusDistance.value = Mathf.Lerp(dof.focusDistance.value, 30f, Time.deltaTime);
        }
    }
}
