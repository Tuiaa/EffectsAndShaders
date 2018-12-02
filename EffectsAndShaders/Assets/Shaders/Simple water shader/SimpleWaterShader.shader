Shader "Custom/SimpleWater"
{
	Properties
	{
		// color of the water
		_Color("Color", Color) = (1, 1, 1, 1)
		// color of the edge effect
		_EdgeColor("Edge Color", Color) = (1, 1, 1, 1)
		// width of the edge effect
		_DepthFactor("Depth Factor", float) = 1.0
		_RampTexture("Ramp texture", 2D) = "white" {}

		_WaveSpeed("Wave speed", float) = 1.0
		_WaveAmp("Wave amp", float) = 1.0
		_NoiseTex("Noise texture", 2D) = "white" {}
	}

	SubShader
	{
		Pass
	{

		CGPROGRAM
		// required to use ComputeScreenPos()
#include "UnityCG.cginc"

#pragma vertex vert
#pragma fragment frag

		// Unity built-in - NOT required in Properties
		sampler2D _CameraDepthTexture;
		
	float4 _Color;
	float4 _EdgeColor;
	float _DepthFactor;
	sampler2D _RampTexture;

	float _WaveSpeed;
	float _WaveAmp;
	sampler2D _NoiseTex;

	struct vertexInput
	{
		float4 vertex : POSITION;
		float2 uv : TEXCOORD0;
	};

	struct vertexOutput
	{
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
		float4 screenPos : TEXCOORD1;
	};

	vertexOutput vert(vertexInput input)
	{
		vertexOutput output;

		// convert obj-space position to camera clip space
		output.pos = UnityObjectToClipPos(input.vertex);

		float noiseSample = tex2Dlod(_NoiseTex, float4(input.uv.xy, 0, 0));
		output.pos.y += sin(_Time * _WaveSpeed * noiseSample) * _WaveAmp;
		output.pos.x += cos(_Time * _WaveSpeed * noiseSample) * _WaveAmp;

		// compute depth (screenPos is a float4)
		output.screenPos = ComputeScreenPos(output.pos);

		return output;
	}

	float4 frag(vertexOutput input) : COLOR
	{
		float4 depthSample = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, input.screenPos);
		float depth = LinearEyeDepth(depthSample).r;

		// apply the DepthFactor to be able to tune at what depth values
		// the foam line actually starts
		float foamLine = 1 - saturate(_DepthFactor * (depth - input.screenPos.w));

		float4 foamRamp = float4(tex2D(_RampTexture, float2(foamLine, 0.5)).rgb, 1.0);

		// multiply the edge color by the foam factor to get the edge,
		// then add that to the color of the water
		float4 col = _Color *  foamRamp;

		return col;
	}

		ENDCG
	} }}