using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace Retroizer
{
    [RequireComponent(typeof(RawImage))]
    public class Retroizer : MonoBehaviour
    {

        public enum Resolution
        {
            _240x135,
            _320x180,
            _480x270,
            _640x360,
            _960x540,
            _Custom
        }

        public enum Orientation
        {
            Landscape,
            Portrait
        }


        public Camera targetCamera { get { return m_TargetCamera; } set { m_TargetCamera = value; Initialize(); } }
        [SerializeField]
        private Camera m_TargetCamera;
        public Resolution resolution { get { return m_Resolution; } set { SetResolution(value); } }
        [SerializeField]
        private Resolution m_Resolution = Resolution._480x270;

        public Orientation orientation { get { return m_Orientation; } set { SetOrientation(value); } }
        [SerializeField]
        private Orientation m_Orientation = Orientation.Landscape;
        RenderTexture target;
        RawImage rawImage;
        [SerializeField]
        Material m_Material;

        [SerializeField]
        uint m_CustomWidth = 240;
        [SerializeField]
        uint m_CustomHeight = 240;

        public void SetResolution(Resolution newResolution)
        {
            if (newResolution != m_Resolution)
            {
                m_Resolution = newResolution;
                Initialize();
            }
        }

        public void SetOrientation(Orientation newOrientation)
        {
            if (newOrientation != m_Orientation)
            {
                m_Orientation = newOrientation;
                Initialize();
            }
        }

        private void OnEnable()
        {
            Initialize();
        }

        private void OnDisable()
        {
            RenderTexture.ReleaseTemporary(target);
            target = null;
            m_Material = null;
        }

        private void OnValidate()
        {
            Initialize();
        }

        private void Initialize()
        {
            rawImage = GetComponent<RawImage>();
            if (m_TargetCamera == null || rawImage == null)
            {
                RenderTexture.ReleaseTemporary(target);
                target = null;
                m_Material = null;
                return;
            }

            if (target != null) RenderTexture.ReleaseTemporary(target);

            int width = -1, height = -1;
            switch (m_Resolution)
            {
                case Resolution._240x135: width = 240; height = 135; break;
                case Resolution._320x180: width = 320; height = 180; break;
                default:
                case Resolution._480x270: width = 480; height = 270; break;
                case Resolution._640x360: width = 640; height = 360; break;
                case Resolution._960x540: width = 960; height = 540; break;
                case Resolution._Custom:
                    if (m_CustomWidth == 0) m_CustomWidth = 1;
                    if (m_CustomHeight == 0) m_CustomHeight = 1;
                    width = (int)m_CustomWidth; height = (int)m_CustomHeight;
                    break;
            }

            if (m_Orientation == Orientation.Portrait)
            {
                var w = width;
                width = height;
                height = w;
            }

            target = RenderTexture.GetTemporary(width, height, 32, RenderTextureFormat.ARGB32);
            target.filterMode = FilterMode.Point;
            m_TargetCamera.targetTexture = target;
            m_Material = new Material(Shader.Find("Hidden/Retroizer"));
            m_Material.SetInt("_Width", width);
            m_Material.SetInt("_Height", height);

            rawImage.material = m_Material;
            rawImage.texture = target;
        }

    }

}
