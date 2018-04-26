using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(Retroizer))]
public class RetroizerEditor : Editor {

    protected Dictionary<string, SerializedProperty> m_Properties;
    
    private void OnEnable()
    {
        if (m_Properties == null)
            m_Properties = new Dictionary<string, SerializedProperty>();

        AddProperty("m_TargetCamera");
        AddProperty("m_Resolution");
        AddProperty("m_Orientation");
        
    }

    private void AddProperty(string name)
    {
        var prop = serializedObject.FindProperty(name);
        if(prop != null)
            m_Properties.Add(name, prop);
    }

    private void OnDisable()
    {
        m_Properties.Clear();
    }

    public override void OnInspectorGUI()
    {
        serializedObject.Update();
        EditorGUI.BeginChangeCheck();
        EditorGUILayout.PropertyField(m_Properties["m_Resolution"], false);
        EditorGUILayout.PropertyField(m_Properties["m_Orientation"], false);
        EditorGUILayout.PropertyField(m_Properties["m_TargetCamera"], false);

        if (EditorGUI.EndChangeCheck())
            serializedObject.ApplyModifiedProperties();
    }
}
