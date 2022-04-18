using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.AI;

public class NPCFollow : MonoBehaviour
{
    [SerializeField] GameObject player;
    [SerializeField] float setFollowSpeed;
    private Vector3 startPos;
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

    // nav mesh
    private NavMeshAgent navMeshAgent;

    // searching
    bool searching;

    
    void Start()
    {
        animator = GetComponent<Animator>();
        npc = this.gameObject;
        npcHead = this.transform.Find("Head Position");
        navMeshAgent = GetComponent<NavMeshAgent>();

        startPos = transform.position;
    }

    // Update is called once per frame
    void Update()
    {
        FollowPlayer();
        Searching();
    }

    void FollowPlayer()
    {
        if (!searching) npcHead.LookAt(player.transform);

        if(Physics.Raycast(npcHead.position, npcHead.TransformDirection(Vector3.forward), out shot)) {
            targetDist = shot.distance;
            if (shot.collider.gameObject.tag == "Player")
            {
                searching = false;
                if (targetDist >= allowedDist) {
                    followSpeed = setFollowSpeed;
                    // old move
                    // transform.position = Vector3.MoveTowards(transform.position, player.transform.position, followSpeed);
                    navMeshAgent.destination = player.transform.position;

                    faceMat.SetColor("_EmissionColor", Color.white * 5);
                    faceLight.color = Color.white;
                }
                else {
                    followSpeed = 0;

                    navMeshAgent.destination = transform.position;

                    faceMat.SetColor("_EmissionColor", Color.red * 8);
                    faceLight.color = Color.red;
                }
            }
            else
            {
                followSpeed = 0;
                navMeshAgent.destination = transform.position;
                faceMat.SetColor("_EmissionColor", Color.yellow * 8);
                faceLight.color = Color.yellow;
                searching = true;
            }
        }

        faceLight.UpdateAfterManualPropertyChange(); // update volumetric light

        animationBlend = Mathf.Lerp(animationBlend, followSpeed, Time.deltaTime * npcSpeedChangeRate);
        animator.SetFloat("Speed", animationBlend);

        Debug.DrawRay(npcHead.position, npcHead.TransformDirection(Vector3.forward) * shot.distance, Color.red);
    }

    void Searching()
    {
        if (searching)
        {
            npcHead.rotation = Quaternion.Euler(npcHead.eulerAngles + Vector3.up * 6 * Time.deltaTime);
        }
    }

    // head look
    void OnAnimatorIK()
    {
        animator.SetLookAtWeight(1, .3f, .5f, 0f, .5f);
        if (!searching) animator.SetLookAtPosition(player.transform.position);
    }
}
