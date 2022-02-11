using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class Teleport : MonoBehaviour
{
    public GameObject player;
    public Transform destination;

    // public bool hasKey;
    public Text keycardText;

    public Renderer rend;
    bool readyToTel;

    public GameObject guidingLight;
    // Start is called before the first frame update
    void Start()
    {
        // rend = GetComponent<Renderer>();
    }

    // Update is called once per frame
    void Update()
    {
        if (readyToTel) {
            float rbVal = 1;
            rbVal -= 1 / 1.5f;
            rend.material.SetColor("_EmissionColor", new Color(rbVal, 1, rbVal));
        }
    }

    IEnumerator elevate() {
        yield return new WaitForSeconds(1.5f);
        player.transform.position = destination.position;
    }

    void OnTriggerEnter (Collider other) {
        if (other.tag == "Player") {
            if (GameManager.Instance.gotKey) {
                readyToTel = true;
                StartCoroutine(elevate());
            }
            else {
                rend.material.SetColor("_EmissionColor", new Color(.75f, 0, 0));
                keycardText.enabled = true;
                guidingLight.SetActive(true);
            }
        }
    }

    void OnTriggerExit (Collider other) {
        if (other.tag == "Player") {
            StopAllCoroutines();
            rend.material.SetColor("_EmissionColor", Color.white);
            readyToTel = false;
            keycardText.enabled = false;
        }
    }
}
