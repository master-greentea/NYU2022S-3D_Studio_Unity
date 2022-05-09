using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FootstepPlayer : MonoBehaviour
{
    [SerializeField] private AudioClip[] footstepSounds;
    private AudioClip lastClip;
    private AudioSource audioSource;
    public float playingVolume;

    private float walkTimer;
    [SerializeField] private float walkInterval;
    [SerializeField] private float runningModifier;

    public bool walking;
    public bool running;

    void Start()
    {
        playingVolume = .35f;
        lastClip = footstepSounds[0];
        audioSource = GetComponent<AudioSource>();
    }

    void Update()
    {
        if (walking) WalkingSteps(1);
        if (running) WalkingSteps(runningModifier);

        audioSource.volume = playingVolume;
    }

    private AudioClip PickStep()
    {
        int newIndex = Random.Range(0, footstepSounds.Length);
        AudioClip newClip = footstepSounds[newIndex];
        if (newClip != lastClip)
        {
            lastClip = newClip;
            return newClip;
        }
        else return footstepSounds[Mathf.Abs(newIndex - 1)];
    }

    void WalkingSteps(float runningModifier)
    {
        if (walkTimer > walkInterval * runningModifier)
        {
            walkTimer = 0;
            audioSource.PlayOneShot(PickStep());
        }
        walkTimer += Time.deltaTime;
    }
}
