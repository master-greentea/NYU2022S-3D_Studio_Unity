using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Flicker : MonoBehaviour
{
    public Light light;
    public float minWait;
    public float maxWait;
    public float waitTime;

    private bool on;
    private float counter;
    // Start is called before the first frame update
    void Start()
    {
        on = true;
        counter = 0;
        StartCoroutine(flak());
    }

    IEnumerator flak() {
        while (counter <= waitTime) {
            yield return new WaitForSeconds(Random.Range(minWait, maxWait));
            on = ! on;
        }
    }

    // Update is called once per frame
    void Update()
    {
        if (on) {
            light.enabled = true;
        }
        else {
            light.enabled = false;
        }
        counter += Time.deltaTime;
        if (counter > waitTime) {
            on = true;
        }
    }
}
