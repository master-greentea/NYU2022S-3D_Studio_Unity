using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class TitleToGame : MonoBehaviour
{
    [SerializeField] private string sceneToGo;
    void Start()
    {
        StartCoroutine(GoToGame(sceneToGo));
    }

    IEnumerator GoToGame(string sceneToGo)
    {
        Cursor.visible = false;
        Cursor.lockState = CursorLockMode.Locked;
        yield return new WaitForSeconds(2);
        SceneManager.LoadScene(sceneToGo);
    }
}
