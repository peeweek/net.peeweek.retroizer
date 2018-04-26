Shader "Hidden/Retroizer"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Width("Width", Int) = 480
		_Height("Height", Int) = 270
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
		
			#pragma shader_feature QUALITY_LOW QUALITY_MID QUALIY_HIGH

			#include "UnityCG.cginc"


			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			int _Height;
			int _Width;

			////////////////////////////////////////////////////////////////////
			////////////////////////////////////////////////////////////////////
			////
			////    VERTEX SHADER : STOLEN FROM NEIGHBOURING SHADERS
			////
			////////////////////////////////////////////////////////////////////
			////////////////////////////////////////////////////////////////////

			////////////////////////////////////////////////////////////////////
			////////////////////////////////////////////////////////////////////
			////    EFFECT CONSTANTS : TWEAK THEM!
			////

					// Size of the border effect
					static const float2 OverscanMaskHardness = float2(12.0 , 12.0);
					// Attenuation of the border effect
					static const float OverscanMaskPower = 4.0;
					// Intensity of the border effect
					static const float OverscanIntensity = 0.96;
		
					// Intensity of the TV Corners (round-ness) deformation 
					static const float TVDeformInstensity = 0.02;
		
		
					// How much R, G and B are offset : default is -0.333 pixels in fake-pixel-space
					static const float ColorFringeIntensity = -0.666;
					// How much luminosity is output by a fake-pixel
					static const float FakePixelMaskGain = 0.75;
					// How much luminosity is output between fake-pixels (adds to the fake-pixel value)
					static const float FakePixelMaskOffset = 0.55;
					// How sharp will appear the pixels (Horizontal Sharpness, Vertical Sharpness A.K.A Scanlines)
					static const float2 FakePixelMaskPower = float2(0.450 ,4.0);
					// Scanline Off Sync (Slides one line out of two)
					static const float ScanlineOffSync = 0.25;
					// Base Brightness
					static const float BaseBrightness = 0.55;
		
					// How much the Fake-Pixel effect is Active (0.0 = normal image, 1.0 = full FakePixel Effect)
					static const float FakePixelEffectBlend = 0.99;

					// Ghost Sampling : enable define to activate
					#define GHOST_SAMPLING;

						static const float GhostLatencyIntensity = 0.03;
						// Number of samples (higer is slower)
						#if defined(QUALITY_LOW)
							static const int GhostNumSamples = 8;
						#elif defined(QUALITY_MID)
							static const int GhostNumSamples = 16;
						#elif defined(QUALIY_HIGH)
							static const int GhostNumSamples = 32;
						#endif


						// Latency of the RGB Signal (per-signal, in screen width percentage)
						static const float3 SignalLatencyRGB = float3(0.184,0.08,0.0624);
						// Attenuation of the ghosting latency
						static const float SignalLatencyAttenuation = 1.0;

					// Bloom : enable define to activate
					#define BLOOM;
						static const float BloomIntensity = 0.75f;
						static const float BloomExponent = 1.00f;
						static const float BloomWeights[5][5] =
						{
							{0.003765,	0.015019,	0.023792,	0.015019,	0.003765},
							{0.015019,	0.059912,	0.094907,	0.059912,	0.015019},
							{0.023792,	0.094907,	0.150342,	0.094907,	0.023792},
							{0.015019,	0.059912,	0.094907,	0.059912,	0.015019},
							{0.003765,	0.015019,	0.023792,	0.015019,	0.003765}			
						};
						static const float BloomPositions[5] = { -2, -1, 0 , 1 , 2};


			////
			////
			////////////////////////////////////////////////////////////////////
			////////////////////////////////////////////////////////////////////

			float expow(float value, float exponent) {
				return lerp(1.0f,pow(value,max(exponent,1.0f)),saturate(exponent));
			}

			// MultiSampling for ghosting effect
			float3 GhostSample(sampler2D s, float2 t, float latency) {

				float3 Out = tex2D(s,t);
				float Weight = 1.0f;
				float2 Direction = float2(-latency,0.0f);
				for(int i=1; i < GhostNumSamples; i++) {
					float curweight = pow(1.0f-((float)i/GhostNumSamples),1.0f/SignalLatencyAttenuation);

					Out += GhostLatencyIntensity * curweight * tex2D(s,saturate(t+(1.0f-curweight)*Direction)).xyz;
					Weight += GhostLatencyIntensity * curweight;
				}
				return Out/Weight;
			}	

			// MultiSampling for ghosting effect
			float3 Bloom(sampler2D s, float2 t, float2 r) {

				float3 Out = float3(0,0,0);
				for(int j = 0; j < 5; j++)
					for(int i = 0; i < 5; i++)
					{
						float2 offset = float2(BloomPositions[i],BloomPositions[j]) / r;
						Out += tex2D(s, t + offset).rgb * BloomWeights[i][j];
					}
				return pow(Out, BloomExponent) * BloomIntensity;
			}

			// Compositing of the TV Emulation
			float3 TVEffect(float2 in_Position, float2 FakeResolution, sampler2D Texture, float Time) {

				// TV Deformation
				float2 ScreenPos = in_Position + dot(in_Position-0.5f,in_Position-0.5f)*(in_Position-0.5f)* TVDeformInstensity;

				// Apply Off-Sync
				ScreenPos += (ScanlineOffSync/FakeResolution.x) * float2(sin((Time*30*3.1415926)+(ScreenPos.y*3.1415926*FakeResolution.y)),0);

				// Sampling 3 Images biased to simulate TV RGB Offset
				#ifdef GHOST_SAMPLING 
					float3 latencyweight = float3(0.0f,0.0f,0.0f);
					for(int i=1; i < GhostNumSamples; i++) {
						latencyweight += tex2D(Texture, ScreenPos + float2(1.0f/FakeResolution.x,0.0f)).xyz;
					}	
					float3 LatencyRGB = SignalLatencyRGB * (1.0-(latencyweight/GhostNumSamples));

					float3 SMP_Red = GhostSample(Texture, (ScreenPos),LatencyRGB.x).xyz;
					float3 SMP_Green = GhostSample(Texture, (ScreenPos) + ((float2(ColorFringeIntensity,0.0f))/FakeResolution),LatencyRGB.y).xyz;
					float3 SMP_Blue = GhostSample(Texture, (ScreenPos) + ((float2(ColorFringeIntensity*2.0f,0.0f))/FakeResolution),LatencyRGB.z).xyz;
				#else
					float3 SMP_Red = tex2D(Texture, (ScreenPos)).xyz;
					float3 SMP_Green = tex2D(Texture, (ScreenPos) + ((float2(ColorFringeIntensity,0.0f))/FakeResolution)).xyz;
					float3 SMP_Blue = tex2D(Texture, (ScreenPos) + ((float2(ColorFringeIntensity*2.0f,0.0f))/FakeResolution)).xyz;
				#endif

				#ifdef BLOOM
					float3 bloom = Bloom(Texture, ScreenPos, FakeResolution);
					SMP_Red += bloom.r;
					SMP_Green += bloom.g;
					SMP_Blue += bloom.b;
				#endif

				// Apply base Brightness
				SMP_Red *= BaseBrightness;
				SMP_Green *= BaseBrightness;
				SMP_Blue *= BaseBrightness;

				// Overscan Darkening Mask
				float2 ScreenMask = pow(saturate(ScreenPos*(1.0f-ScreenPos)*OverscanMaskHardness),1.0f/OverscanMaskPower);
				float mask = lerp(1.0, ScreenMask.x * ScreenMask.y, OverscanIntensity);
	
				// CRT Cell Masks (HorizontalRGB+Scanline)
				float PixelMaskR = expow(saturate(4*frac(ScreenPos.x*FakeResolution.x)*(1.0f-frac(ScreenPos.x*FakeResolution.x))),FakePixelMaskPower.x);
				float PixelMaskG = expow(saturate(4*frac(ScreenPos.x*FakeResolution.x+float2(ColorFringeIntensity,0.0f))*(1.0f-frac(ScreenPos.x*FakeResolution.x+float2(ColorFringeIntensity,0.0f)))),FakePixelMaskPower.x);
				float PixelMaskB = expow(saturate(4*frac(ScreenPos.x*FakeResolution.x+float2(ColorFringeIntensity*2.0f,0.0f))*(1.0f-frac(ScreenPos.x*FakeResolution.x+float2(ColorFringeIntensity*2.0f,0.0f)))),FakePixelMaskPower.x);
				float PixelMaskScanline = pow(saturate(4*frac(ScreenPos.y*FakeResolution.y)*(1.0f-frac(ScreenPos.y*FakeResolution.y))),FakePixelMaskPower.y);

				float3 PixelRGB = float3 ( 
											((PixelMaskR*PixelMaskScanline * FakePixelMaskGain)+FakePixelMaskOffset)  * SMP_Red.x ,
											((PixelMaskG*PixelMaskScanline * FakePixelMaskGain)+FakePixelMaskOffset)  * SMP_Green.y ,
											((PixelMaskB*PixelMaskScanline * FakePixelMaskGain)+FakePixelMaskOffset)  * SMP_Blue.z
											);

				// Non-Pixelated Image
				float3 ImageRGB = tex2D(Texture, ScreenPos).xyz;
				return lerp(ImageRGB, PixelRGB, FakePixelEffectBlend) * mask;
	
				//return float3(PixelMaskR*PixelMaskScanline,PixelMaskG*PixelMaskScanline,PixelMaskB*PixelMaskScanline);
			}


			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}
			
			float4 frag (v2f i) : SV_Target
			{
				int2 resolution = int2(_Width, _Height);
				return float4(TVEffect(i.uv, resolution, _MainTex, _Time.y),1);
			}
			ENDCG
		}
	}
}
