using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Teleport : MonoBehaviour
{
    public GameObject player;
    public Transform destination;
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {

    }

    IEnumerator elevate() {
        yield return new WaitForSeconds(1.5f);
        player.transform.position = destination.position;
    }

    void OnTriggerEnter (Collider other) {
        if (other.tag == "Player") {
            StartCoroutine(elevate());
        }
    }

    void OnTriggerExit (Collider other) {
        if (other.tag == "Player") {
            StopAllCoroutines();
        }
    }
}
