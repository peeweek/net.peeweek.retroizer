using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Rotate : MonoBehaviour {

    public Vector3 Axis = Vector3.up;
    public float Speed;
    
	// Update is called once per frame
	void Update () {
        transform.Rotate(Axis, Speed * Time.deltaTime);
	}
}
