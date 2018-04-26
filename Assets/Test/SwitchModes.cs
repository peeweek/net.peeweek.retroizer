using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

[RequireComponent(typeof(Retroizer))]
public class SwitchModes : MonoBehaviour
{
    public KeyCode SwitchCode = KeyCode.Space;
    public Text ShowResolution;
    private void Start()
    {
        Application.targetFrameRate = 15;
        ShowResolution.text = GetComponent<Retroizer>().resolution.ToString();
    }

    private void Update()
    {
        if (Input.GetKeyDown(SwitchCode) || Input.GetMouseButtonDown(0) || (Input.touchCount > 0 && Input.GetTouch(0).phase == TouchPhase.Began))
        {
            var c = GetComponent<Retroizer>();
            c.resolution = (Retroizer.Resolution)(((int)c.resolution+1) % 5);
            ShowResolution.text = GetComponent<Retroizer>().resolution.ToString();
        }

    }
}
