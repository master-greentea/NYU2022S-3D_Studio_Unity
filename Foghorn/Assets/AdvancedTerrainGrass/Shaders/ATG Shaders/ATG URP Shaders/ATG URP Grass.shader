// Shader uses custom editor to set double sided GI
// Needs _Culling to be set properly

Shader "AdvancedTerrainGrass URP/Grass"
{
    Properties
    {
        [Header(Surface Options)]
        [Space(8)]
        [Enum(UnityEngine.Rendering.CullMode)]
        _Cull                               ("Culling", Float) = 0
        [Toggle(_ALPHATEST_ON)]
        _AlphaClip                          ("Alpha Clipping", Float) = 1.0
        _Cutoff                             ("    Threshold", Range(0.0, 1.0)) = 0.5
        _CutoffShadows                      ("    Threshold Shadows", Range(0.0, 1.0)) = 0.5
        [ToggleOff(_RECEIVE_SHADOWS_OFF)]
        _ReceiveShadows                     ("Receive Shadows", Float) = 1.0
        [Toggle(_RECEIVESSAO)]
        _SSAO                               ("Receive SSAO", Float) = 1.0
        _SSAOStrength                       ("    Strength", Range(0.0, 1.0)) = 0.5

        [Space(8)]
        [Toggle(_VSPSETUP)]
        _VSP                                ("Enable VSP Support", Float) = 0.0
        _VSPScaleMultiplier                 ("    VSP Scale Multiplier", Float) = 1.0
        _VSPCullDist                        ("    VSP Cull Distance", Float) = 80.0
        _VSPCullFade                        ("    VSP Cull Fade", Float) = 0.001

        [Header(Surface Inputs)]
        [Space(8)]
        [NoScaleOffset] [MainTexture]
        _MainTex                            ("Albedo (RGB) Alpha (A)", 2D) = "white" {}

        [Toggle(_TEXTUREARRAYS)]
        _TextureArrays                      ("Enable Texture Arrays", Float) = 0
        [NoScaleOffset] _MainTexArray       ("    Albedo (RGB) Alpha (A) Array", 2DArray) = "white" {}
        
        [Space(8)]
        [HideInInspector] _MinMaxScales     ("MinMaxScale Factors", Vector) = (1,1,1,1)
        _HealthyColor                       ("Healthy Color (RGB) Bending (A)", Color) = (1,1,1,1)
        _DryColor                           ("Dry Color (RGB) Bending (A)", Color) = (1,1,1,1)
        
        [Header(Lighting)]
        [Space(8)]
        [Toggle(_NORMAL)] _SampleNormal     ("Use NormalBuffer", Float) = 0
        _NormalBend                         ("Bend Normal", Range(0,4)) = 1

        [Space(5)]
        [Toggle(_MASKMAP)] _EnableMask      ("Enable Mask Map", Float) = 1
        [NoScaleOffset] _SpecTex            ("    Trans (R) Spec Mask (G) Smoothness (B)", 2D) = "black" {}
        [NoScaleOffset] _SpecTexArray       ("    Trans (R) Spec Mask (G) Smoothness (B) Array", 2DArray) = "black" {}
        [Space(5)]
        _Smoothness                         ("Smoothness", Range(0.0, 1.0)) = 0.5
        _SpecColor                          ("Specular", Color) = (0.2, 0.2, 0.2)
        _Occlusion                          ("Occlusion", Range(0.0, 1.0)) = 0.5
        [Space(5)]
        _AmbientReflection                  ("Ambient Reflection", Range(0.0, 1.0)) = 1

        [Header(Transmission)]
        [Space(8)]
        _TranslucencyPower                  ("Power", Range(0.0, 10.0)) = 7.0
        _TranslucencyStrength               ("Strength", Range(0.0, 1.0)) = 1.0
        _ShadowStrength                     ("Shadow Strength", Range(0.0, 1.0)) = 0.7
        _Distortion                         ("Distortion", Range(0.0, 0.1)) = 0.01

        [Header(Two Step Culling)]
        [Space(8)]
        _Clip                               ("Clip Threshold", Range(0.0, 1.0)) = 0.3
        [Enum(XYZ,0,XY,1)]
        _ScaleMode                          ("Scale Mode", Float) = 0

        [Header(Wind)]
        [Space(8)]
        [KeywordEnum(Alpha, Blue)]
        _BendingMode                        ("Main Bending", Float) = 0
        [ATGWindGrassDrawer]
        _WindMultiplier                     ("Wind Strength (X) Jitter Strength (Y) Sample Size (Z) Lod Level (W)", Vector) = (1, 2, 1, 0)

        [Header(Touch Bending)]
        [Space(8)]
        [Toggle(_GRASSDISPLACEMENT)]
        _EnableDisplacement                 ("Enable Touch Bending", Float) = 0
        _DisplacementSampleSize             ("    Sample Size", Range(0.0, 1)) = .5
        _DisplacementStrength               ("    Displacement XZ", Range(0.0, 16.0)) = 4
        _DisplacementStrengthVertical       ("    Displacement Y", Range(0.0, 16.0)) = 4
        _NormalDisplacement                 ("    Normal Displacement", Range(-2, 2)) = 1

        [Header(Advanced)]
        [Space(8)]
        [Toggle(_BLINNPHONG)]
        _BlinnPhong                         ("Enable Blinn Phong Lighting", Float) = 0.0
        [Space(8)]
        [ToggleOff]
        _SpecularHighlights                 ("Enable Specular Highlights", Float) = 1.0
        [ToggleOff]
        _EnvironmentReflections             ("Environment Reflections", Float) = 1.0

    //  Needed by Meta pass
        [HideInInspector] _BaseMap          ("Base Map", 2D) = "white" {}
    //  Needed by the inspector
        [HideInInspector] _Culling  ("Culling", Float) = 0.0
    //  Lightmapper and outline selection shader need _MainTex, _Color and _Cutoff
        [HideInInspector] _Color    ("Color", Color) = (1,1,1,1)
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "UniversalMaterialType" = "Lit"
            "IgnoreProjector" = "True"
            "Queue"="AlphaTest"
        }
        LOD 300

        Pass
        {
            Name "ForwardLit"
            Tags{"LightMode" = "UniversalForward"}
            ZWrite On
            Cull [_Cull]

            HLSLPROGRAM
            #pragma target 3.0

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _VSPSETUP

            #pragma shader_feature_local _ALPHATEST_ON
            #define _SPECULAR_SETUP 1
            #pragma shader_feature_local_fragment _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature_local_fragment _ENVIRONMENTREFLECTIONS_OFF
            #pragma shader_feature_local _RECEIVE_SHADOWS_OFF

        //  Do we use the sampled terrain normal?
            #pragma shader_feature_local _NORMAL
            #pragma shader_feature_local _MASKMAP
            #pragma shader_feature_local _TEXTUREARRAYS

            #pragma shader_feature_local _GRASSDISPLACEMENT

            #pragma shader_feature_local _BENDINGMODE_BLUE

            #pragma shader_feature_local _BLINNPHONG

            #pragma shader_feature_local_fragment _RECEIVESSAO

        //  Needed to make BlinnPhong work
            #define _SPECULAR_COLOR

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile_fog

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma instancing_options assumeuniformscaling procedural:setup

        //  Include base inputs and all other needed "base" includes
            #include "Includes/ATG URP Grass Inputs.hlsl"
            #include "Includes/ATG Instanced Indirect Inputs.hlsl"

            #pragma vertex LitPassVertex
            #pragma fragment LitPassFragment


        //--------------------------------------
        //  Vertex shader

            VertexOutput LitPassVertex(VertexInput input)
            {
                VertexOutput output = (VertexOutput)0;
                
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

            //  Wind in WorldSpace -------------------------------
                VertexPositionInputs vertexInput;
                vertexInput.positionWS = 0; //TransformObjectToWorld(input.positionOS.xyz);

                #if defined(_NORMAL)
                    input.normalOS = terrainNormal;
                #else
                    input.normalOS = half3(0,1,0);
                #endif
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

                output.uv.xy = input.texcoord;
                OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);

                half4 instanceColor = 0;
                bool clipped = false;
                bendGrass (vertexInput.positionWS, input.positionOS, normalInput.normalWS, input.color, instanceColor, clipped);
                if (clipped) {
                    output.positionCS = input.positionOS.xxxx / (1-clipped);
                    return output;
                }

                output.instanceColor = instanceColor;
                output.layer = (uint)TextureLayer;

            //  We have to recalculate ClipPos! / see: GetVertexPositionInputs in Core.hlsl
                vertexInput.positionVS = TransformWorldToView(vertexInput.positionWS);
                vertexInput.positionCS = TransformWorldToHClip(vertexInput.positionWS);
                float4 ndc = vertexInput.positionCS * 0.5f;
                vertexInput.positionNDC.xy = float2(ndc.x, ndc.y * _ProjectionParams.x) + ndc.w;
                vertexInput.positionNDC.zw = vertexInput.positionCS.zw;
            
            //  End Wind -------------------------------

                half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);
                half fogFactor = ComputeFogFactor(vertexInput.positionCS.z);

                #ifdef _NORMALMAP
                    output.normalWS = normalInput.normalWS;
                    real sign = input.tangentOS.w * GetOddNegativeScale();
                    output.tangentWS = half4(normalInput.tangentWS.xyz, sign);
                #else
                    output.normalWS = normalInput.normalWS;
                #endif

                OUTPUT_SH(output.normalWS.xyz, output.vertexSH);
                output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);

                #if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
                    output.positionWS = vertexInput.positionWS;
                #endif

                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    output.shadowCoord = GetShadowCoord(vertexInput);
                #endif

                output.positionCS = vertexInput.positionCS;
                return output;
            }

        //--------------------------------------
        //  Fragment shader and functions

            inline void InitializeGrassLitSurfaceData(float2 uv, uint layer, half occlusion, out SurfaceDescription outSurfaceData)
            {
                #if !defined(_TEXTUREARRAYS)
                    half4 albedoAlpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_MainTex, sampler_MainTex));
                #else
                    half4 albedoAlpha = SAMPLE_TEXTURE2D_ARRAY(_MainTexArray, sampler_MainTexArray, uv, layer);
                #endif

            //  Early out
                outSurfaceData.alpha = Alpha(albedoAlpha.a, 1, _Cutoff);
                
                outSurfaceData.albedo = albedoAlpha.rgb;
                outSurfaceData.metallic = 0;
                outSurfaceData.specular = _SpecColor;
            //  Normal Map currently not supported
                #if defined (_NORMALMAP)
                    //outSurfaceData.normalTS = SampleNormal(uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap));
                    half4 sampleNormal = SAMPLE_TEXTURE2D(_BumpSpecMap, sampler_BumpSpecMap, uv);
                    half3 tangentNormal;
                    tangentNormal.xy = sampleNormal.ag * 2 - 1;
                    tangentNormal.z = sqrt(1.0 - dot(tangentNormal.xy, tangentNormal.xy));  
                    outSurfaceData.normalTS = tangentNormal;
                #else
                    outSurfaceData.normalTS = float3(0, 0, 1);
                #endif

                outSurfaceData.smoothness = _Smoothness;

                #if defined(_MASKMAP)
                    #if !defined(_TEXTUREARRAYS)
                        half3 combinedSample = SAMPLE_TEXTURE2D(_SpecTex, sampler_SpecTex, uv).rgb;
                    #else
                        half3 combinedSample = SAMPLE_TEXTURE2D_ARRAY(_SpecTexArray, sampler_SpecTexArray, uv, layer).rgb;
                    #endif
                    outSurfaceData.smoothness *= combinedSample.b;
                    outSurfaceData.translucency = combinedSample.r;
                    outSurfaceData.specular *= combinedSample.g;
                #else
                    outSurfaceData.translucency = 1;
                #endif

                outSurfaceData.occlusion = occlusion;
                outSurfaceData.emission = 0;
            }

            void InitializeInputData(VertexOutput input, half3 normalTS, out InputData inputData)
            {
                inputData = (InputData)0;
                #if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
                    inputData.positionWS = input.positionWS;
                #endif

                half3 viewDirWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
                #ifdef _NORMALMAP
                    half sgn = input.tangentWS.w;
                    half3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
                    inputData.normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, bitangentWS.xyz, input.normalWS.xyz));
                #else
                    inputData.normalWS = input.normalWS;
                #endif

                inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
                inputData.viewDirectionWS = viewDirWS;
                
                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    inputData.shadowCoord = input.shadowCoord;
                #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
                    inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
                #else
                    inputData.shadowCoord = float4(0, 0, 0, 0);
                #endif

                inputData.fogCoord = input.fogFactorAndVertexLight.x;
                inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
                inputData.bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, inputData.normalWS);

                inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
                inputData.shadowMask = SAMPLE_SHADOWMASK(input.lightmapUV);
            }

            half4 LitPassFragment(VertexOutput input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

            //  Get the surface description
                SurfaceDescription surfaceData;
                InitializeGrassLitSurfaceData(input.uv.xy, input.layer, input.instanceColor.a, surfaceData);

                surfaceData.albedo *= input.instanceColor.rgb;

            //  Prepare surface data (like bring normal into world space) and get missing inputs like gi
                InputData inputData;
                InitializeInputData(input, surfaceData.normalTS, inputData);

            //  Apply lighting
                #if defined(_BLINNPHONG)
                    surfaceData.smoothness = max(0.01, surfaceData.smoothness);
                    half4 color = UniversalFragmentBlinnPhong(inputData, surfaceData.albedo, half4(surfaceData.specular, surfaceData.smoothness), surfaceData.smoothness, surfaceData.emission, surfaceData.alpha);
                #else
                    //half4 color = LightweightFragmentPBR(inputData, surfaceData.albedo, surfaceData.metallic, surfaceData.specular, surfaceData.smoothness, surfaceData.occlusion, surfaceData.emission, surfaceData.alpha);

                    //  Apply lighting
                half4 color = ATGURPTranslucentFragmentPBR(
                    inputData, 
                    surfaceData.albedo, 
                    surfaceData.metallic, 
                    surfaceData.specular, 
                    surfaceData.smoothness, 
                    surfaceData.occlusion, 
                    surfaceData.emission, 
                    surfaceData.alpha,
                    half4(_TranslucencyStrength * surfaceData.translucency, _TranslucencyPower, _ShadowStrength, _Distortion),
                    _AmbientReflection,
                    _SSAOStrength
                );

                #endif
            //  Add fog
                color.rgb = MixFog(color.rgb, inputData.fogCoord);
                return color;
            }

            ENDHLSL
        }


    //  Shadows -----------------------------------------------------
        
        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 3.0

            #define ISSHADOWPASS

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _VSPSETUP

            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature_local _TEXTUREARRAYS

            #pragma shader_feature_local _GRASSDISPLACEMENT

            #pragma shader_feature_local _BENDINGMODE_BLUE

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma instancing_options assumeuniformscaling procedural:setup

        //  Include base inputs and all other needed "base" includes
            #include "Includes/ATG URP Grass Inputs.hlsl"
            #include "Includes/ATG Instanced Indirect Inputs.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            
        //  Shadow caster specific input
            float3 _LightDirection;

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            VertexOutput ShadowPassVertex(VertexInput input)
            {
                VertexOutput output = (VertexOutput)0;
                UNITY_SETUP_INSTANCE_ID(input);
                //UNITY_TRANSFER_INSTANCE_ID(input, output);

                float3 positionWS = 0; //TransformObjectToWorld(input.positionOS.xyz);

                #if defined(_NORMAL)
                    input.normalOS = terrainNormal;
                #else
                    input.normalOS = half3(0,1,0);
                #endif

            //  Calculate world space normal
                half3 normalWS = TransformObjectToWorldNormal(input.normalOS);    

            //  Wind in WorldSpace -------------------------------
            
            //  Do other stuff here
                #if defined(_ALPHATEST_ON)
                    output.uv = input.texcoord;
                    output.layer = (uint)TextureLayer;
                #endif

            //  Add bending
                half4 dummyInstanceColor = 0;
                bool clipped = false;
                bendGrass (positionWS, input.positionOS, normalWS, input.color, dummyInstanceColor, clipped);
                if (clipped) {
                    output.positionCS = input.positionOS.xxxx / (1-clipped);
                    return output;
                }

            //  We have to recalculate ClipPos! / see: GetVertexPositionInputs in Core.hlsl
            //  End Wind -------------------------------  

                output.positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));
                #if UNITY_REVERSED_Z
                    output.positionCS.z = min(output.positionCS.z, output.positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #else
                    output.positionCS.z = max(output.positionCS.z, output.positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #endif
                return output;
            }

            half4 ShadowPassFragment(VertexOutput input) : SV_TARGET
            {
                //UNITY_SETUP_INSTANCE_ID(input);
                #if defined(_ALPHATEST_ON)
                    #if !defined(_TEXTUREARRAYS)
                        Alpha(SampleAlbedoAlpha(input.uv.xy, TEXTURE2D_ARGS(_MainTex, sampler_MainTex)).a, half4(1,1,1,1), _CutoffShadows);
                    #else
                        half alpha = SAMPLE_TEXTURE2D_ARRAY(_MainTexArray, sampler_MainTexArray, input.uv, input.layer).a;
                        clip(alpha - _CutoffShadows);
                    #endif
                #endif
                return 0;
            }
            ENDHLSL
        }

    //  Depth -----------------------------------------------------

        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ColorMask 0
            Cull [_Cull]

            HLSLPROGRAM
            #pragma target 3.0

            #define ISDEPTHPASS

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _VSPSETUP

            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature_local _TEXTUREARRAYS

            #pragma shader_feature_local _GRASSDISPLACEMENT

            #pragma shader_feature_local _BENDINGMODE_BLUE

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma instancing_options assumeuniformscaling procedural:setup
            
            #define DEPTHONLYPASS
            #include "Includes/ATG URP Grass Inputs.hlsl"
            #include "Includes/ATG Instanced Indirect Inputs.hlsl"

            VertexOutput DepthOnlyVertex(VertexInput input)
            {
                VertexOutput output = (VertexOutput)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                VertexPositionInputs vertexInput;
                vertexInput.positionWS = TransformObjectToWorld(input.positionOS.xyz);

                #if defined(_ALPHATEST_ON)
                    output.uv.xy = input.texcoord;
                    output.layer = (uint)TextureLayer;
                #endif

            //  Add bending
                half3 dummyNormal = 1;
                half4 dummyInstanceColor = 0;
                bool clipped = false;
                bendGrass (vertexInput.positionWS, input.positionOS, dummyNormal, input.color, dummyInstanceColor, clipped);            
                if (clipped) {
                    output.positionCS = input.positionOS.xxxx / (1-clipped);
                    return output;
                }

            //  We have to recalculate ClipPos!
                output.positionCS = TransformWorldToHClip(vertexInput.positionWS);
                return output;
            }

            half4 DepthOnlyFragment(VertexOutput input) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                #if defined(_ALPHATEST_ON)
                    #if !defined(_TEXTUREARRAYS)
                        Alpha(SampleAlbedoAlpha(input.uv.xy, TEXTURE2D_ARGS(_MainTex, sampler_MainTex)).a, half4(1,1,1,1), _Cutoff);
                    #else
                        half alpha = SAMPLE_TEXTURE2D_ARRAY(_MainTexArray, sampler_MainTexArray, input.uv, input.layer).a;
                        clip(alpha - _Cutoff);
                    #endif
                #endif
                return 0;
            }

            ENDHLSL
        }

    //  DepthNormal -----------------------------------------------------
        Pass
        {
            Name "DepthNormals"
            Tags{"LightMode" = "DepthNormals"}

            ZWrite On
            Cull [_Cull]

            HLSLPROGRAM
            #pragma target 3.0

            #define ISDEPTHPASS

            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _VSPSETUP
            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature_local _TEXTUREARRAYS

            #pragma shader_feature_local _GRASSDISPLACEMENT

            #pragma shader_feature_local _BENDINGMODE_BLUE

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma instancing_options assumeuniformscaling procedural:setup
            
            #define DEPTHNORMALPASS
            #include "Includes/ATG URP Grass Inputs.hlsl"
            #include "Includes/ATG Instanced Indirect Inputs.hlsl"

            VertexOutput DepthNormalsVertex(VertexInput input)
            {
                VertexOutput output = (VertexOutput)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                VertexPositionInputs vertexInput;
                vertexInput.positionWS = TransformObjectToWorld(input.positionOS.xyz);

                #if defined(_ALPHATEST_ON)
                    output.uv.xy = input.texcoord;
                    output.layer = (uint)TextureLayer;
                #endif

                #if defined(_NORMAL)
                    input.normalOS = terrainNormal;
                #else
                    input.normalOS = half3(0,1,0);
                #endif
            //  Calculate world space normal
                half3 normalWS = TransformObjectToWorldNormal(input.normalOS); 

            //  Add bending
                half4 dummyInstanceColor = 0;
                bool clipped = false;
                bendGrass (vertexInput.positionWS, input.positionOS, normalWS, input.color, dummyInstanceColor, clipped);            
                if (clipped) {
                    output.positionCS = input.positionOS.xxxx / (1-clipped);
                    return output;
                }

            //  We have to recalculate ClipPos!
                output.positionCS = TransformWorldToHClip(vertexInput.positionWS);
                output.normalWS = NormalizeNormalPerVertex(normalWS);
                return output;
            }

            half4 DepthNormalsFragment(VertexOutput input) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                #if defined(_ALPHATEST_ON)
                    #if !defined(_TEXTUREARRAYS)
                        Alpha(SampleAlbedoAlpha(input.uv.xy, TEXTURE2D_ARGS(_MainTex, sampler_MainTex)).a, half4(1,1,1,1), _Cutoff);
                    #else
                        half alpha = SAMPLE_TEXTURE2D_ARRAY(_MainTexArray, sampler_MainTexArray, input.uv, input.layer).a;
                        clip(alpha - _Cutoff);
                    #endif
                #endif
                return float4(PackNormalOctRectEncode(TransformWorldToViewDir(input.normalWS, true)), 0.0, 0.0);
            }

            ENDHLSL
        }

    //  Meta -----------------------------------------------------
        
        Pass
        {
            Name "Meta"
            Tags{"LightMode" = "Meta"}

            Cull Off

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles

            #pragma vertex UniversalVertexMeta
            #pragma fragment UniversalFragmentMeta

            #define _SPECULAR_SETUP 1
            #pragma shader_feature_local _ALPHATEST_ON
            // 1

        //  First include all our custom stuff
            #include "Includes/ATG URP Grass Inputs.hlsl"

        //--------------------------------------
        //  Fragment shader and functions - usually defined in LitInput.hlsl

            inline void InitializeStandardLitSurfaceData(float2 uv, out SurfaceData outSurfaceData)
            {
                outSurfaceData = (SurfaceData)0;
                half4 albedoAlpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_MainTex, sampler_MainTex));
                outSurfaceData.alpha = Alpha(albedoAlpha.a, half4(1.0h, 1.0h, 1.0h, 1.0h), _Cutoff);
                outSurfaceData.albedo = albedoAlpha.rgb;
                outSurfaceData.metallic = 1.0h; // crazy?
                outSurfaceData.specular = _SpecColor;
                outSurfaceData.smoothness = _Smoothness;
                outSurfaceData.normalTS = half3(0,0,1);
                outSurfaceData.occlusion = 1;
                outSurfaceData.emission = 0.5h;
            }

        //  Finally include the meta pass related stuff  
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitMetaPass.hlsl"

            ENDHLSL
        }

    //  End Passes -----------------------------------------------------
    
    }
    FallBack "Hidden/InternalErrorShader"
    //CustomEditor "LuxLWRPCustomSingleSidedShaderGUI"
}
