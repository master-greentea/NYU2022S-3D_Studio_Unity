using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.SceneManagement;

public class DamageEffect : MonoBehaviour
{
    private Volume damageVolume;

    private Vignette vnt;
    private ChromaticAberration chroma;
    private ColorAdjustments colorAdj;
    private Bloom dirt;

    public bool takingDamage;
    public bool brokenContact;
    public bool transitioning;

    // post process profiles to tune
    [SerializeField] private float targetVntIntensity = .3f;
    private float vntIntensity;
    [SerializeField] private float targetChromaIntensity = 1;
    private float chromaIntensity;
    [SerializeField] private float targetPostExposure = 4;
    private float postExposure;
    [SerializeField] private float targetContrast = 100;
    private float contrast;
    [SerializeField] private float targetSaturation = -80;
    private float saturation;
    [SerializeField] private float targetDirtIntensity = 40f;
    private float dirtIntesity;
    [SerializeField] private Texture bloodVessels;
    private Texture dirtTexture;

    private float damageFilterTimer;
    [SerializeField] private float damageDuration;
    private float resetTimer;
    private float resetDuration = 2;

    // audio
    private AudioSource audioSource;

    
    void Start()
    {
        damageVolume = GetComponent<Volume>();
        audioSource = GetComponent<AudioSource>();

        damageVolume.profile.TryGet<Vignette>( out vnt );
        damageVolume.profile.TryGet<ChromaticAberration>( out chroma );
        damageVolume.profile.TryGet<ColorAdjustments>( out colorAdj );
        damageVolume.profile.TryGet<Bloom>( out dirt );

        damageFilterTimer = damageDuration + 1;
        StoreOriginalValues();
    }

    void Update()
    {
        if (takingDamage) {damageFilterTimer = 0; takingDamage = false; audioSource.volume = 1; audioSource.Play();}
        if (brokenContact) {damageFilterTimer = damageDuration + 1; brokenContact = false;}
        
        if (damageFilterTimer < damageDuration)
        {
            TakingDamageEffect();
            damageFilterTimer += Time.deltaTime;
            transitioning = true;
        }
        else if (damageFilterTimer > damageDuration && damageFilterTimer < damageDuration + 1)
        {
            Debug.Log("dead");
            SceneManager.LoadScene("Death");
        }
        else if (resetTimer < resetDuration)
        {
            ResetEffect();
            resetTimer += Time.deltaTime;
        }
        else transitioning = false;
    }

    void StoreOriginalValues()
    {
        vntIntensity = vnt.intensity.value;

        chromaIntensity = chroma.intensity.value;

        postExposure = colorAdj.postExposure.value;
        contrast = colorAdj.contrast.value;
        saturation = colorAdj.saturation.value;

        dirtIntesity = dirt.dirtIntensity.value;
        dirtTexture = dirt.dirtTexture.value;
    }

    void TakingDamageEffect()
    {
        vnt.intensity.value = Mathf.Lerp(vntIntensity, targetVntIntensity, damageFilterTimer / damageDuration);
        vnt.color.value = Color.red;

        chroma.intensity.value = Mathf.Lerp(chromaIntensity, targetChromaIntensity, damageFilterTimer / damageDuration);

        colorAdj.postExposure.value = Mathf.Lerp(postExposure, targetPostExposure, damageFilterTimer / damageDuration);
        colorAdj.contrast.value = Mathf.Lerp(contrast, targetContrast, damageFilterTimer / damageDuration);
        colorAdj.saturation.value = Mathf.Lerp(saturation, targetSaturation, damageFilterTimer / damageDuration);
        
        dirt.dirtIntensity.value = Mathf.Lerp(dirtIntesity, targetDirtIntensity, damageFilterTimer / damageDuration);
        dirt.dirtTexture.value = bloodVessels;

        resetTimer = 0;
    }

    void ResetEffect()
    {
        vnt.intensity.value = Mathf.Lerp(vnt.intensity.value, vntIntensity, resetTimer / resetDuration);
        vnt.color.value = Color.black;

        chroma.intensity.value = Mathf.Lerp(chroma.intensity.value, chromaIntensity, resetTimer / resetDuration);

        colorAdj.postExposure.value = Mathf.Lerp(colorAdj.postExposure.value, postExposure, resetTimer / resetDuration);
        colorAdj.contrast.value = Mathf.Lerp(colorAdj.contrast.value, contrast, resetTimer / resetDuration);
        colorAdj.saturation.value = Mathf.Lerp(colorAdj.saturation.value, saturation, resetTimer / resetDuration);
        
        dirt.dirtIntensity.value = Mathf.Lerp(dirt.dirtIntensity.value, dirtIntesity, resetTimer / resetDuration);
        dirt.dirtTexture.value = dirtTexture;

        audioSource.volume = Mathf.Lerp(audioSource.volume, 0, resetTimer / resetDuration);
    }
}
