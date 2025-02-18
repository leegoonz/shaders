#ifndef MULTISTEPPARALLAX_INCLUDED
#define MULTISTEPPARALLAX_INCLUDED

float _ParallaxOffset;
float _Parallax;
float _ParallaxSteps;
Texture2D _ParallaxMap;
float4 _ParallaxMap_TexelSize;

float3 CalculateTangentViewDir(float3 tangentViewDir)
{
    tangentViewDir = Unity_SafeNormalize(tangentViewDir);
    tangentViewDir.xy /= (tangentViewDir.z + 0.42);
    // tangentViewDir.xy /= tangentViewDir.z;
	return tangentViewDir;
}

float2 ParallaxOffsetMultiStep(float surfaceHeight, float strength, float2 uv, float3 tangentViewDir)
{
	float stepSize = 1.0 / _ParallaxSteps;
    float3 uvDelta_stepSize = float3(tangentViewDir.xy * (stepSize * strength), stepSize);
    float3 uvOffset_stepHeight = float3(float2(0, 0), 1.0);
    
    float2 minUvSize = GetMinUvSize(uv, _ParallaxMap_TexelSize);
    float lod = ComputeTextureLOD(minUvSize);

    //float prevSurfaceHeight = surfaceHeight;

    float previousStepHeight = 0;
    float previousSurfaceHeight = 0;
    float2 previousUVOffset = 0;

    [loop]
    for (int j = 0; j < _ParallaxSteps; j++)
    {
        if (uvOffset_stepHeight.z < surfaceHeight)
        {
            break;
        }

        previousStepHeight = uvOffset_stepHeight.z;
        previousSurfaceHeight = surfaceHeight;
        previousUVOffset = uvOffset_stepHeight.xy;


        uvOffset_stepHeight -= uvDelta_stepSize;
        surfaceHeight = _ParallaxMap.SampleLevel(sampler_MainTex, (uv + uvOffset_stepHeight.xy), lod) + _ParallaxOffset;
    }

    // taken from filamented cause it looks better https://gitlab.com/s-ilent/filamented
    float previousDifference = previousStepHeight - previousSurfaceHeight;
    float delta = surfaceHeight - uvOffset_stepHeight.z;
    uvOffset_stepHeight.xy = previousUVOffset - uvDelta_stepSize.xy * previousDifference / (previousDifference + delta);

    // [unroll]
    // for (int k = 0; k < 3; k++)
    // {
    //     uvDelta_stepSize *= 0.5;
        
    //     uvOffset_stepHeight += uvDelta_stepSize * ((uvOffset_stepHeight.z < surfaceHeight) * 2.0 - 1.0);
    //     surfaceHeight = _ParallaxMap.Sample(sampler_MainTex, (uv + uvOffset_stepHeight.xy)) + _ParallaxOffset;
    // }


    return uvOffset_stepHeight.xy;
}

float2 ParallaxOffset (float3 viewDirForParallax, float2 parallaxUV)
{
    viewDirForParallax = CalculateTangentViewDir(viewDirForParallax);
    float h = _ParallaxMap.Sample(sampler_MainTex, parallaxUV);
    h = clamp(h, 0.0, 0.999);
    float2 offset = ParallaxOffsetMultiStep(h, _Parallax, parallaxUV, viewDirForParallax);

	return offset;
}

// parallax from mochie
// https://github.com/MochiesCode/Mochies-Unity-Shaders/blob/7d48f101d04dac11bd4702586ee838ca669f426b/Mochie/Standard%20Shader/MochieStandardParallax.cginc#L13
// MIT License

// Copyright (c) 2020 MochiesCode

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
#endif