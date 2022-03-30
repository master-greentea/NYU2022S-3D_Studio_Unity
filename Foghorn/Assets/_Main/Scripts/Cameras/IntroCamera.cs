using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class IntroCamera : MonoBehaviour
{
    public GameObject mainCamStandIn;
    public GameObject mainCam;
    void Start()
    {
        mainCamStandIn.SetActive(true);
        StartCoroutine(MainCamActive());
    }

    IEnumerator MainCamActive() {
        yield return new WaitForSeconds(8);
        mainCam.SetActive(true);
        mainCamStandIn.SetActive(false);
        this.gameObject.SetActive(false);
    }
}
