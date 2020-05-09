// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

#if !defined(POWER_VFX_CGINC)
    #define POWER_VFX_CGINC

    fixed4 _Color;
    float _ColorScale;
    sampler2D _MainTex;
    half4 _MainTex_ST;
    int _MainTexOffsetStop;
    int _MainTexOffsetUseCustomData_XY;

    int _DoubleEffectOn; //2层效果,
    sampler2D _MainTexMask;
    float4 _MainTexMask_ST;
    int _MainTexMaskUseR;

    #if defined(DISTORTION_ON)
        sampler2D _NoiseTex;
        half4 _NoiseTex_ST;
        sampler2D _DistortionMaskTex;
        float _DistortionIntensity;
        float4 _DistortTile,_DistortDir;
    #endif

    #if defined(DISSOLVE_ON)
        sampler2D _DissolveTex;
        int _DissolveByVertexColor;
        int _DissolveByCustomData;
        int _DissolveTexUseR;
        float4 _DissolveTex_ST;
        float _Cutoff;
        float _EdgeWidth;
        float4 _EdgeColor;
        float _EdgeColorIntensity;
    #endif

    #if defined(OFFSET_ON)
        sampler2D _OffsetTex;
        sampler2D _OffsetMaskTex;
        int _OffsetMaskTexUseR;
        float4 _OffsetTexColorTint,_OffsetTexColorTint2;
        float4 _OffsetTile,_OffsetDir;
        float _BlendIntensity;
    #endif

    #if defined(_GRAB_PASS)
        sampler2D _ScreenTex;
    #endif

    #if defined(FRESNAL_ON)
    float4 _FresnalColor;
    float _FresnalPower;
    int _FresnalTransparentOn;
    float _FresnalTransparent;
    #endif

    #if defined(ENV_REFLECT)
    samplerCUBE _EnvMap;
    sampler2D _EnvMapMask;
    int _EnvMapMaskUseR;
    float _EnvIntensity;
    float4 _EnvOffset;
    #endif

    sampler2D _MatCapTex;
    float _MatCapIntensity;

    struct appdata
    {
        float4 vertex : POSITION;
        float3 normal:NORMAL;
        float4 color : COLOR;
        half4 uv : TEXCOORD0; // xy:main uv,zw : particle's customData
        half4 uv1:TEXCOORD1;
    };

    struct v2f
    {
        float4 uv : TEXCOORD0;
        float4 vertex : SV_POSITION;
        float4 color : COLOR;
        float3 reflectDir:COLOR1;
        float2 viewNormal:COLOR2;

        float4 distortUV : TEXCOORD1;
        float4 offsetUV:TEXCOORD2;
        float4 dissolveUV:TEXCOORD3;
        float4 grabPos:TEXCOORD4;
        float4 fresnal:TEXCOORD5;// x:fresnal,y:customData.x
    };

    void ApplyMainTexOffset(inout v2f o,in appdata v){
        float2 offsetScale = lerp(_Time.xx, 1 ,_MainTexOffsetStop);
        float2 mainTexOffset = (_MainTex_ST.zw * offsetScale);
        mainTexOffset = lerp(mainTexOffset,v.uv.zw, _MainTexOffsetUseCustomData_XY); // vertex uv0.z : particle customData1.xy

        o.uv.xy = v.uv.xy * _MainTex_ST.xy + mainTexOffset;
        o.uv.zw = v.uv.xy;
    }

    v2f vert(appdata v)
    {
        v2f o = (v2f)0;
        o.color = v.color;
        o.vertex = UnityObjectToClipPos(v.vertex);

        ApplyMainTexOffset(o,v);

        #if defined(DISTORTION_ON)
            o.distortUV = v.uv.xyxy * _DistortTile + frac(_DistortDir * _Time.xxxx);
        #endif

        #if defined(DISSOLVE_ON)
            o.dissolveUV.xy = TRANSFORM_TEX(v.uv.xy,_DissolveTex);
        #endif

        #if defined(OFFSET_ON)
            o.offsetUV = v.uv.xyxy * _OffsetTile + (_Time.xxxx * _OffsetDir); //暂时去除 frac
        #endif

        #if defined(_GRAB_PASS)
            o.grabPos = ComputeGrabScreenPos(o.vertex);
        #endif

        float3 worldPos = mul(unity_ObjectToWorld,v.vertex);
        float3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
        float3 worldNormal = normalize(UnityObjectToWorldNormal(v.normal));

        #if defined(ENV_REFLECT)
        o.reflectDir = reflect(- viewDir,worldNormal + _EnvOffset.xyz);
        #endif

        float3 viewNormal = normalize(mul((float3x3)UNITY_MATRIX_MV,v.normal));
        o.viewNormal = viewNormal.xy * 0.5 + 0.5;

        #if defined(FRESNAL_ON)
            o.fresnal.x = 1 - dot(worldNormal,viewDir) ;
        #endif

        o.fresnal.y = v.uv1.x;// particle customData.z
        return o;
    }

    float4 SampleMainTex(float2 uv,float4 vertexColor){
        #if defined(_GRAB_PASS)
            float4 mainTex = tex2D(_ScreenTex,uv);
        #else
            float4 mainTex = tex2D(_MainTex,uv);
        #endif
        return mainTex * _Color * vertexColor * _ColorScale;
    }

    void ApplyMainTexMask(inout float4 mainColor,float2 uv){
        float4 maskTex = tex2D(_MainTexMask,uv*_MainTexMask_ST.xy + _MainTexMask_ST.zw);// fp opearate mask uv.
        float mask = _MainTexMaskUseR > 0 ? maskTex.r : maskTex.a;
        mainColor.a *= mask;
    }

    void ApplyDistortion(inout float4 mainColor,float2 mainUV,float4 distortUV,float4 color){
        #if defined(DISTORTION_ON)
            half3 noise = (tex2D(_NoiseTex, distortUV.xy));

            noise += _DoubleEffectOn > 0 ? tex2D(_NoiseTex, distortUV.zw).rgb : 0;
            // center noise uv.
            noise = (noise -0.5)*2;

            half3 ramp = tex2D(_DistortionMaskTex,mainUV);
            half2 uv = mainUV + noise * 0.2  * _DistortionIntensity * ramp.r;
            mainColor = SampleMainTex(uv,color);
        #endif
    }

    void ApplyDissolve(inout float4 mainColor,float2 dissolveUV,float4 color,float customData){
        #if defined(DISSOLVE_ON)
            half4 edgeColor = (half4)0;

            half4 dissolveTex = tex2D(_DissolveTex,dissolveUV.xy);
            half dissolve = lerp(dissolveTex.a,dissolveTex.r,_DissolveTexUseR);
            half gray = 1 - dissolve;

            // select cutoff
            half cutoff = _DissolveByVertexColor > 0 ? 1 - color.a : _Cutoff; // slider or vertex color
            cutoff = _DissolveByCustomData >0 ? 1- customData :cutoff; // slider or particle's custom data
            cutoff = lerp(-0.1,1.01,cutoff);

            half a = gray - cutoff;
            clip(a);

            #if defined(DISSOLVE_EDGE_ON)
                half edgeRate = cutoff + _EdgeWidth;
                half edge = step(gray,edgeRate);
                edgeColor = edge * _EdgeColor * _EdgeColorIntensity;

                // edge color fadeout.
                edgeColor.a *= cutoff < 0.6 ? 1 : exp(-cutoff);
                // apply mainTex alpha
                edgeColor.a *= mainColor.a;
                mainColor = lerp(mainColor,edgeColor,edge);
            #endif
        #endif

    }

    void ApplyOffset(inout float4 color,float4 offsetUV,float2 mainUV){
        #if defined(OFFSET_ON)
            half4 offsetColor = tex2D(_OffsetTex,offsetUV.xy) * _OffsetTexColorTint;
            offsetColor += _DoubleEffectOn > 0 ? tex2D(_OffsetTex,offsetUV.zw) * _OffsetTexColorTint2 : 0;

            half4 offsetMask = tex2D(_OffsetMaskTex,mainUV);
            float mask = _OffsetMaskTexUseR > 0? offsetMask.r : offsetMask.a;

            offsetColor = offsetColor * _BlendIntensity * mask;
            color.rgb *= lerp(1,offsetColor,mask);
        #endif
    }

    void ApplyFresnal(inout float4 mainColor,float fresnal){
        #if defined(FRESNAL_ON)
        float f =  saturate(smoothstep(fresnal,0,_FresnalPower));
        float4 fresnalColor = _FresnalColor *f * _FresnalColor.a;
        mainColor.rgb = mainColor.rgb * 0.9 + fresnalColor;
        mainColor.a *= lerp(_FresnalTransparent + f*2,mainColor.a,step(_FresnalTransparentOn,0));
        #endif
    }

    void ApplyEnvReflection(inout float4 mainColor,float2 mainUV,float3 reflectDir){
        #if defined(ENV_REFLECT)
        float4 maskMap = tex2D(_EnvMapMask,mainUV);
        float mask = _EnvMapMaskUseR > 0?maskMap.r:maskMap.a;

        float4 envMap = texCUBE(_EnvMap,reflectDir);
        envMap *= _EnvIntensity * mask;
        mainColor.rgb += envMap.rgb;
        #endif
    }

    void ApplyMatcap(inout float4 mainColor,float2 mainUV,float2 viewNormal){
        float4 matCapMap = tex2D(_MatCapTex,viewNormal.xy);
        matCapMap *= _MatCapIntensity;
        mainColor.rgb += matCapMap;
    }

    fixed4 frag(v2f i) : SV_Target
    {
        half4 mainColor = float4(0,0,0,1);
        // setup mainUV
        float4 mainUV = i.uv;
        #if defined(_GRAB_PASS)
            mainUV.xy = i.grabPos.xy/i.grabPos.w;
        #endif
        
        #if defined(DISTORTION_ON)
            ApplyDistortion(mainColor,mainUV.xy,i.distortUV,i.color);
        #else
            mainColor = SampleMainTex(mainUV.xy,i.color);
        #endif

        ApplyMainTexMask(mainColor,mainUV.zw);
        ApplyMatcap(mainColor,mainUV.zw,i.viewNormal);

        #if defined(ENV_REFLECT)
        ApplyEnvReflection(mainColor,mainUV.zw,i.reflectDir);
        #endif

        #if defined(OFFSET_ON)
            ApplyOffset(mainColor,i.offsetUV,i.uv.zw);
        #endif

        //dissolve
        #if defined(DISSOLVE_ON)
            ApplyDissolve(mainColor,i.dissolveUV,i.color,i.fresnal.y);
        #endif
        #if defined(FRESNAL_ON)
        ApplyFresnal(mainColor,i.fresnal.x);
        #endif

        return mainColor;
    }

#endif //POWER_VFX_CGINC