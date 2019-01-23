using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

namespace Retroizer
{
    [CustomEditor(typeof(Retroizer))]
    public class RetroizerEditor : Editor
    {
        protected Dictionary<string, SerializedProperty> m_Properties;

        private void OnEnable()
        {
            if (m_Properties == null)
                m_Properties = new Dictionary<string, SerializedProperty>();

            AddProperty("m_TargetCamera");
            AddProperty("m_Resolution");
            AddProperty("m_Orientation");
            AddProperty("m_CustomWidth");
            AddProperty("m_CustomHeight");

        }

        private void AddProperty(string name)
        {
            var prop = serializedObject.FindProperty(name);
            if (prop != null)
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
            if (m_Properties["m_Resolution"].intValue == (int)Retroizer.Resolution._Custom)
            {
                EditorGUILayout.PropertyField(m_Properties["m_CustomWidth"], false);
                EditorGUILayout.PropertyField(m_Properties["m_CustomHeight"], false);
            }
            EditorGUILayout.PropertyField(m_Properties["m_Orientation"], false);
            EditorGUILayout.PropertyField(m_Properties["m_TargetCamera"], false);

            if (EditorGUI.EndChangeCheck())
                serializedObject.ApplyModifiedProperties();
        }
    }

}
