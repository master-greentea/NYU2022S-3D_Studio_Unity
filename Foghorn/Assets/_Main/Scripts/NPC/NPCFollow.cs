using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.AI;
using UnityEngine.VFX;

public class NPCFollow : MonoBehaviour
{
    [SerializeField] private GameObject player;
    [SerializeField] private float setFollowSpeed;
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
    private bool searching;
    private bool rotationReset;
    private Transform searchGuide;
    [SerializeField] private float searchSpeed;
    [SerializeField] private float searchAngle;

    // detection logic
    private bool canDetect;
    private bool foundPlayer = true;
    private bool canUndetect;
    private bool brokenContact;
    [SerializeField] float detectionTime;
    [SerializeField] float undetectionTime;

    // light pulsing
    private bool pulsing;
    private float pulseTimer;

    // vfx
    public VisualEffect vfx;
    
    void Start()
    {
        animator = GetComponent<Animator>();
        npc = this.gameObject;
        npcHead = this.transform.Find("Head Position");
        searchGuide = npcHead.Find("Search Guide");
        navMeshAgent = GetComponent<NavMeshAgent>();
    }

    // detecting player
    IEnumerator Detecting()
    {
        searching = false;
        pulsing = true; pulseTimer = 0;
        vfx.Play();
        yield return new WaitForSeconds(detectionTime);
        foundPlayer = true;
        pulsing = false;
    }

    // undetecting player
    IEnumerator UnDetecting()
    {
        yield return new WaitForSeconds(undetectionTime);
        brokenContact = true;
        canUndetect = true;
    }

    void Update()
    {
        FollowPlayer();

        if (searching) Searching();
        if (pulsing) LightPulse();
    }

    void FollowPlayer()
    {
        if (!searching) npcHead.LookAt(player.transform); // lock raycast to player when not searching

        if(Physics.Raycast(npcHead.position, npcHead.TransformDirection(Vector3.forward), out shot)) {
            targetDist = shot.distance;

            // if raycast hits player
            if (shot.collider.gameObject.tag == "Player")
            {
                if (foundPlayer)
                {
                    rotationReset = false;
                    canUndetect = true;
                    brokenContact = false;
                    faceLight.gameObject.GetComponent<VLB.EffectPulse>().enabled = false;

                    // keep tracking player
                    if (targetDist >= allowedDist) {
                        followSpeed = setFollowSpeed;
                        navMeshAgent.destination = player.transform.position;
                        faceMat.SetColor("_EmissionColor", Color.white * 5);
                        faceLight.color = Color.white;
                    }
                    // stop and turn red when too close to player
                    else {
                        followSpeed = 0;
                        navMeshAgent.destination = transform.position;
                        faceMat.SetColor("_EmissionColor", Color.red * 8);
                        faceLight.color = Color.red;
                    }
                }
                // detection logic
                if (!foundPlayer && canDetect)
                {
                    StartCoroutine(Detecting());
                    canDetect = false;
                }

                FacePlayer(); // keep facing player
            }
            // if raycast doesn't hit player
            else
            {
                if (brokenContact)
                {
                    followSpeed = 0;
                    navMeshAgent.destination = transform.position;
                    faceMat.SetColor("_EmissionColor", Color.yellow * 8);
                    faceLight.color = Color.yellow;

                    searching = true;
                    canDetect = true;
                    foundPlayer = false;
                    // StopAllCoroutines();
                }
                // detection logic
                if (!brokenContact && canUndetect)
                {
                    StartCoroutine(UnDetecting());
                    canUndetect = false;
                }
            }
        }

        faceLight.UpdateAfterManualPropertyChange(); // update volumetric light

        // animation blends
        animationBlend = Mathf.Lerp(animationBlend, followSpeed, Time.deltaTime * npcSpeedChangeRate);
        animator.SetFloat("Speed", animationBlend);

        Debug.DrawRay(npcHead.position, npcHead.TransformDirection(Vector3.forward) * shot.distance, Color.red);
    }

    // searching for player
    void Searching()
    {
        // reset rotation to 000
        if (!rotationReset)
        {
            npcHead.localRotation = Quaternion.Euler(0, 0, 0);
            rotationReset = true;
        }
        // scan for player
        else
        {
            float rY = Mathf.SmoothStep(-searchAngle, searchAngle ,Mathf.PingPong(Time.time * searchSpeed, 1));
            npcHead.localRotation = Quaternion.Euler(0, rY, 0);
        }

        faceLight.gameObject.GetComponent<VLB.EffectPulse>().enabled = false;
    }

    void FacePlayer()
    {
        Quaternion rot = Quaternion.LookRotation(player.transform.position - transform.position);
        transform.rotation = Quaternion.Slerp(transform.rotation, rot, Time.deltaTime * .35f);
    }

    void LightPulse()
    {
        if (pulseTimer < 1.5f)
        {
            faceMat.SetColor("_EmissionColor", Color.Lerp(Color.yellow * 8, Color.white * 5, pulseTimer / 1.5f));
            pulseTimer += Time.deltaTime;
        }
        faceLight.gameObject.GetComponent<VLB.EffectPulse>().enabled = true;
    }

    // head look
    void OnAnimatorIK()
    {
        animator.SetLookAtWeight(.75f, .15f, .8f, 0f, .5f);
        if (!searching) animator.SetLookAtPosition(player.transform.position);
        else animator.SetLookAtPosition(searchGuide.position);
    }
}
