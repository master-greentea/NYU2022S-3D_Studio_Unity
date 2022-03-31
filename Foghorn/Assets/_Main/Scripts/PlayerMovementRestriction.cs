using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;

public class PlayerMovementRestriction : MonoBehaviour
{
    // Start is called before the first frame update
    void Start()
    {
        StartCoroutine(StartupRestriction());
    }

    IEnumerator StartupRestriction()
    {
        yield return new WaitForSeconds(1.5f);
        this.GetComponent<PlayerInput>().enabled = true;
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
