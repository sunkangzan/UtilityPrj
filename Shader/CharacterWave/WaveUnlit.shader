﻿// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Custom/Wave/Unlit/WaveUnlit"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
//wave1
        _WaveColor("WaveColor",color) = (0,0.8,0,0)
        _WaveColorSaturation("WaveColorSaturation",float) = 1
        _WaveTex("_WaveTex",2d) = ""{}
        _WaveSpeed("WaveSpeed",float) = 2
        _Bright("Bright",float) = 1
        _BrightThreshold("BrightThreshold",range(0,1))= 0.1
        _RimPower("RimPower",float) = 2
//wave2
        _WaveColor2("WaveColor2",color) = (0,0.8,0,0)
        _WaveTex2("_WaveTex2",2d) = ""{}
        _WaveSpeed2("WaveSpeed2",float) = 2
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Transparent"}
        LOD 100

        Pass
        {
            blend srcAlpha oneMinusSrcAlpha
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "WaveInclude.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal:NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 worldPos:TEXCOORD2;
                float3 worldNormal:TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                o.worldNormal = mul(v.normal,unity_WorldToObject);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 finalWaveCol = BlendWave(i.worldNormal,i.worldPos,i.uv);
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                
                col.a *= finalWaveCol.r;
                col.rgb += finalWaveCol;
                return col;
            }
            ENDCG
        }
    }
}
