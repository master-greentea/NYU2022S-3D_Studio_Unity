using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class NPCFollow : MonoBehaviour
{
    [SerializeField] GameObject player;
    [SerializeField] float setFollowSpeed;
    public float allowedDist;
    private float targetDist;
    private GameObject npc;
    private float followSpeed;

    // head ray
    private Transform npcHead;
    private RaycastHit shot;

    private Animator animator;
    private float animationBlend;
    public float npcSpeedChangeRate;

    // lights
    [SerializeField] Material faceMat;
    [SerializeField] VLB.VolumetricLightBeam faceLight;
    
    void Start()
    {
        animator = GetComponent<Animator>();
        npc = this.gameObject;
        npcHead = this.transform.Find("Head Position");
    }

    // Update is called once per frame
    void Update()
    {
        FollowPlayer();
    }

    void FollowPlayer()
    {
        transform.LookAt(player.transform);
        if(Physics.Raycast(npcHead.position, transform.TransformDirection(Vector3.forward), out shot)) {
            targetDist = shot.distance;
            if (targetDist >= allowedDist) {
                followSpeed = setFollowSpeed;
                transform.position = Vector3.MoveTowards(transform.position, player.transform.position, followSpeed);

                faceMat.SetColor("_EmissionColor", Color.white * 5);
                faceLight.color = Color.white;
            }
            else {
                followSpeed = 0;

                faceMat.SetColor("_EmissionColor", Color.red * 8);
                faceLight.color = Color.red;
            }
        }

        faceLight.UpdateAfterManualPropertyChange();

        animationBlend = Mathf.Lerp(animationBlend, followSpeed, Time.deltaTime * npcSpeedChangeRate);
        animator.SetFloat("Speed", animationBlend);

        Debug.DrawRay(npcHead.position, transform.TransformDirection(Vector3.forward) * shot.distance, Color.red);
    }

    void OnAnimatorIK()
    {
        animator.SetLookAtWeight(1, .3f, .5f, 0f, .5f);
        animator.SetLookAtPosition(player.transform.Find("PlayerCameraRoot").position);
    }
}
