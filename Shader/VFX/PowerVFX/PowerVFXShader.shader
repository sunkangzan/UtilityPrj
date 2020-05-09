﻿// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
Shader "ZX/FX/PowerVFXShader"
{
	Properties
	{
		_MainTex("Main Texture", 2D) = "white" {}
		[Toggle]_MainTexOffsetStop("禁用MainTex自动滚动?",int)=0
		[Toggle]_MainTexOffsetUseCustomData_XY("_MainTexOffsetUseCustomData_XY -> uv.zw",int)=0
		[HDR]_Color("Main Color",Color) = (1,1,1,1)
		_ColorScale("ColorScale",range(1,3)) = 1
		[Header(MaskTexMask)]
		_MainTexMask("Main Texture Mask(R)", 2D) = "white" {}
		[Toggle]_MainTexMaskUseR("_MainTexMaskUseR",int) = 1

		[Header(MatCap)]
		[noscaleoffset]_MatCapTex("_MapCapTex",2d)=""{}
		_MatCapIntensity("_MatCapIntensity",float) = 1

		[Header(BlendMode)]
		[Enum(UnityEngine.Rendering.BlendMode)]_SrcMode("Src Mode",int) = 5
		[Enum(UnityEngine.Rendering.BlendMode)]_DstMode("Dst Mode",int) = 10

		[Header(DoubleEffect)]
		[Toggle(_DoubleEffectOn)]_DoubleEffectOn("双重效果?",int)=0
		
		[Header(CullMode)]
		[Enum(UnityEngine.Rendering.CullMode)]_CullMode("Cull Mode",float) = 2
		[Toggle]_ZWriteMode("ZWriteMode",int) = 0

		[Header(Distortion)]
		[Toggle(DISTORTION_ON)]_DistortionOn("Distortion On?",int)=0
		[noscaleoffset]_NoiseTex("Noise Texture",2D) = "white" {}
		[noscaleoffset]_DistortionMaskTex("Distortion Mask Tex(R)",2d) = "white"{}
		_DistortionIntensity("Distortion Intensity",Range(0,1)) = 0.5

		_DistortTile("Distort Tile",vector) = (1,1,1,1)
		_DistortDir("Distort Dir",vector) = (0,1,0,-1)


		[Header(Dissolve)]
		[Toggle(DISSOLVE_ON)]_DissolveOn("Dissolve On?",int)=0
		_DissolveTex("Dissolve Tex",2d)=""{}
		[Toggle]_DissolveTexUseR("_DisolveTexUse R(uncheck use A)?",int)=0
		
		[Header(DissolveType)]
		[Toggle]_DissolveByVertexColor("Dissolve By Vertex Color ?",int)=0
		[Toggle]_DissolveByCustomData("Dissolve By customData.z -> uv1.x ?",int)=0
		_Cutoff ("AlphaTest cutoff", Range(0,1)) = 0.5

		[Header(DissolveEdge)]
		[Toggle(DISSOLVE_EDGE_ON)]_DissolveEdgeOn("Dissolve Edge On?",int)=0
		[HDR]_EdgeColor("EdgeColor",color) = (1,0,0,1)
		_EdgeWidth("EdgeWidth",range(0,0.3)) = 0.1
		_EdgeColorIntensity("EdgeColorIntensity",range(1,10)) = 1

		[Header(Offset)]
		[Toggle(OFFSET_ON)] _OffsetOn("Offset On?",int) = 0
		[NoScaleOffset]_OffsetTex("Offset Tex",2d) = ""{}
		[NoScaleOffset]_OffsetMaskTex("Offset Mask (R)",2d) = "white"{}
		[Toggle]_OffsetMaskTexUseR("_OffsetMaskTexUseR",int) = 1
		[HDR]_OffsetTexColorTint("OffsetTex Color",color) = (1,1,1,1)
		[HDR]_OffsetTexColorTint2("OffsetTex Color 2",color) = (1,1,1,1)
		_OffsetTile("Offset Tile",vector) = (1,1,1,1)
		_OffsetDir("Offset Dir",vector) = (1,1,0,0)
		_BlendIntensity("Blend Intensity",range(0,10)) = 0.5

		[Header(Fresnal)]
		[Toggle(FRESNAL_ON)]_FresnalOn("Fresnal On?",int)=0
		_FresnalColor("Fresnal Color",color) = (1,1,1,1)
		_FresnalPower("Fresnal Power",range(0,1)) = 0.5
		[Toggle]_FresnalTransparentOn("Fresnal Transparent?",range(0,1)) = 0
		_FresnalTransparent("_FresnalTransparent",range(0,1)) = 0
		
		[Header(EnvReflection)]
		[Toggle(ENV_REFLECT)]_EnvReflectOn("EnvReflect On?",int)=0
		[NoScaleOffset]_EnvMap("Env Map",Cube) = ""{}
		[NoScaleOffset]_EnvMapMask("Env Map Mask",2d) = ""{}
		[Toggle]_EnvMapMaskUseR("EnvMapMaskUseR",int)=1
		_EnvIntensity("Env intensity",float) = 1
		_EnvOffset("EnvOffset",vector) = (0,0,0,0)
	}
	SubShader
	{
		Tags{ "Queue" = "Transparent" "RenderType" = "Transparent" }

		Pass
		{
			//Tags{ "LightMode" = "ForwardBase" }
			Lighting Off 
			ZWrite[_ZWriteMode]
			Blend [_SrcMode][_DstMode] //,srcAlpha oneMinusSrcAlpha
			Cull[_CullMode]
			CGPROGRAM
			
			#pragma shader_feature DISTORTION_ON
			#pragma shader_feature DISSOLVE_ON
			#pragma shader_feature DISSOLVE_EDGE_ON
			#pragma shader_feature OFFSET_ON
			#pragma shader_feature FRESNAL_ON
			#pragma shader_feature ENV_REFLECT

			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "PowerVFX.cginc"

			ENDCG
		}
	}

	CustomEditor "PowerVFX.PowerVFXInspector"
}