using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class GameManager : MonoBehaviour
{
    // This is private, so that we can show an error if its not set up yet
    private static GameManager staticInstance;

    public bool gotKey = false;
    public Text keyText;

    public static GameManager Instance
    {
        get
        {
            // If the static instance isn't set yet, throw an error
            if (staticInstance is null)
            {
                Debug.LogError("Game Manager is NULL");
            }

            return staticInstance;
        }
    }

    private void Awake()
    {
        // Set the static instance to this instance
        staticInstance = this;
    }

    private IEnumerator RemoveText() {
        yield return new WaitForSeconds(2.5f);
        keyText.enabled = false;
    }

    public void UnlockElevator() {
        Debug.Log("unlocked");
        gotKey = true;
        keyText.text = "KEY ACCUIRED";
        keyText.enabled = true;
        StartCoroutine(RemoveText());
    }
}
