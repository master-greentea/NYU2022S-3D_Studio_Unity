using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class HeadBob : MonoBehaviour
{
    [SerializeField] private bool enable = true;

    [SerializeField, Range(0, .1f)] private float amplitude = .015f;
    [SerializeField, Range(0, 30)] private float frequency = 10f;

    [SerializeField] private Transform camTarget = null;
    // [SerializeField] private Transform camHolder = null;

    private float toggleSpeed = 3f;
    private Vector3 startPos;
    private CharacterController fpc;

    void Awake()
    {
        fpc = GetComponent<CharacterController>();
        startPos = camTarget.localPosition;
    }

    private void CheckMotion()
    {
        float speed = new Vector3(fpc.velocity.x, 0, fpc.velocity.z).magnitude;

        if (speed < toggleSpeed) return;
        if (!fpc.isGrounded) return;

        PlayMotion(FootStepMotion());
    }

    private Vector3 FootStepMotion()
    {
        Vector3 pos = Vector3.zero;
        pos.y += Mathf.Sin(Time.time * frequency) * amplitude;
        pos.x += Mathf.Cos(Time.time * frequency / 2) * amplitude * 2;

        return pos;
    }

    private void ResetPosition()
    {
        if (camTarget.localPosition == startPos) return;
        camTarget.localPosition = Vector3.Lerp(camTarget.localPosition, startPos, 1 * Time.deltaTime);
    }

    private void PlayMotion(Vector3 motion)
    {
        camTarget.localPosition += motion;
    }

    // private Vector3 FocusTarget()
    // {
    //     Vector3 pos = new Vector3(transform.position.x, transform.position.y + camHolder.localPosition.y, transform.position.z);
    //     pos += camHolder.forward * 15;
    //     return pos;
    // }

    void Update()
    {
        if (!enable) return;

        CheckMotion();
        ResetPosition();
        // camTarget.LookAt(FocusTarget());
    }
}
