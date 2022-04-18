using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.AI;

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
    // [SerializeField] VLB.VolumetricLightBeam faceLight;

    // nav mesh
    private NavMeshAgent navMeshAgent;

    // searching
    bool searching;
    bool rotationReset;
    private Transform searchGuide;
    [SerializeField] float searchSpeed;
    [SerializeField] float searchAngle;

    
    void Start()
    {
        animator = GetComponent<Animator>();
        npc = this.gameObject;
        npcHead = this.transform.Find("Head Position");
        searchGuide = npcHead.Find("Search Guide");
        navMeshAgent = GetComponent<NavMeshAgent>();
    }

    // Update is called once per frame
    void Update()
    {
        FollowPlayer();

        if (searching) Searching();
    }

    void FollowPlayer()
    {
        if (!searching) npcHead.LookAt(player.transform);

        if(Physics.Raycast(npcHead.position, npcHead.TransformDirection(Vector3.forward), out shot)) {
            targetDist = shot.distance;
            if (shot.collider.gameObject.tag == "Player")
            {
                searching = false;
                rotationReset = false;

                if (targetDist >= allowedDist) {
                    followSpeed = setFollowSpeed;
                    navMeshAgent.destination = player.transform.position;

                    faceMat.SetColor("_EmissionColor", Color.white * 5);
                    // faceLight.color = Color.white;
                }
                else {
                    followSpeed = 0;

                    navMeshAgent.destination = transform.position;

                    faceMat.SetColor("_EmissionColor", Color.red * 8);
                    // faceLight.color = Color.red;
                }

                FacePlayer();
            }
            else
            {
                followSpeed = 0;
                navMeshAgent.destination = transform.position;
                faceMat.SetColor("_EmissionColor", Color.yellow * 8);
                // faceLight.color = Color.yellow;
                searching = true;
            }
        }

        // faceLight.UpdateAfterManualPropertyChange(); // update volumetric light

        animationBlend = Mathf.Lerp(animationBlend, followSpeed, Time.deltaTime * npcSpeedChangeRate);
        animator.SetFloat("Speed", animationBlend);

        Debug.DrawRay(npcHead.position, npcHead.TransformDirection(Vector3.forward) * shot.distance, Color.red);
    }

    void Searching()
    {
        if (!rotationReset)
        {
            npcHead.rotation = Quaternion.Euler(0, 0, 0);
            rotationReset = true;
        }

        else
        {
            float rY = Mathf.SmoothStep(-searchAngle, searchAngle ,Mathf.PingPong(Time.time * searchSpeed, 1));
            npcHead.rotation = Quaternion.Euler(0, rY, 0);
            // Debug.Log(rY);
        }
    }

    void FacePlayer()
    {
        Quaternion rot = Quaternion.LookRotation(player.transform.position - transform.position);
        transform.rotation = Quaternion.Slerp(transform.rotation, rot, Time.deltaTime * .35f);
    }

    // head look
    void OnAnimatorIK()
    {
        animator.SetLookAtWeight(.75f, .15f, .8f, 0f, .5f);
        if (!searching) animator.SetLookAtPosition(player.transform.position);
        else animator.SetLookAtPosition(searchGuide.position);
    }
}
