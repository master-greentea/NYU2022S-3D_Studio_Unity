Shader "AdvancedTerrainGrass URP/Foliage"
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
        [ToggleOff(_RECEIVE_SHADOWS_OFF)]
        _ReceiveShadows                     ("Receive Shadows", Float) = 1.0
        [Toggle(_RECEIVESSAO)]
        _SSAO                               ("Receive SSAO", Float) = 1.0
        _SSAOStrength                       ("    Strength", Range(0.0, 1.0)) = 1.0

        [Space(8)]
        [Toggle(_VSPSETUP)]
        _VSP                                ("Enable VSP Support", Float) = 0.0
        _VSPScaleMultiplier                 ("    VSP Scale Multiplier", Float) = 1.0
        _VSPCullDist                        ("    VSP Cull Distance", Float) = 80.0
        _VSPCullFade                        ("    VSP Cull Fade", Float) = 0.001

        [Header(Surface Inputs)]
        [Space(8)]
        [NoScaleOffset][MainTexture]
        _MainTex                            ("Albedo (RGB) Alpha (A)", 2D) = "white" {}

        [Space(5)]
        [HideInInspector]_MinMaxScales      ("MinMaxScale Factors", Vector) = (1,1,1,1)
        _HealthyColor                       ("Healthy Color", Color) = (1,1,1,1)
        _DryColor                           ("Dry Color", Color) = (1,1,1,1)

        [Space(5)]
        _Smoothness                         ("Smoothness", Range(0.0, 1.0)) = 0.5
        _SpecColor                          ("Specular", Color) = (0.2, 0.2, 0.2)

        [Space(5)]
        [Toggle(_NORMALMAP)]
        _ApplyNormal                        ("Enable Normal Smoothness Trans Map", Float) = 0.0
        [NoScaleOffset] _BumpSpecMap
                                            ("    Normal (AG) Smoothness (B) Trans (R)", 2D) = "white" {}

        [Header(Transmission)]
        [Space(8)]
        _TranslucencyPower                  ("Power", Range(0.0, 10.0)) = 7.0
        _TranslucencyStrength               ("Strength", Range(0.0, 1.0)) = 1.0
        _ShadowStrength                     ("Shadow Strength", Range(0.0, 1.0)) = 0.7
        _Distortion                         ("Distortion", Range(0.0, 0.1)) = 0.01

        [Header(Wind)]
        [Space(8)]
        [KeywordEnum(Math, Texture)]
        _Wind                               ("Wind Input", Float) = 0
        [ATGWindFoliageDrawer]
        _WindMultiplier                     ("Wind Strength (X) Secondary Strength (Y) Edge Flutter (Z) Lod Level (W)", Vector) = (1, 2, 1, 0)
        _SampleSize                         ("Sample Size", Range(0.0, 2.0)) = 0.5


        [Header(Touch Bending)]
        [Space(8)]
        [Toggle(_GRASSDISPLACEMENT)]
        _EnableDisplacement                 ("Enable Touch Bending", Float) = 0
        _DisplacementSampleSize             ("    Sample Size", Range(0.0, 1)) = .5
        _DisplacementStrength               ("    Displacement Strength", Range(0.0, 3)) = 1


        [Header(Advanced)]
        [Space(8)]
        [ToggleOff]
        _SpecularHighlights                 ("Enable Specular Highlights", Float) = 1.0
        [ToggleOff]
        _EnvironmentReflections             ("Environment Reflections", Float) = 1.0

    //  Needed by Meta pass
        [HideInInspector] _BaseMap          ("Base Map", 2D) = "white" {}
    //  Needed by the inspector
        [HideInInspector] _Culling          ("Culling", Float) = 0.0
    //  Lightmapper and outline selection shader need _MainTex, _Color and _Cutoff
        [HideInInspector] _Color            ("Color", Color) = (1,1,1,1)
    }

    SubShader
    {
        Tags{
            "RenderType" = "TransparentCutout"
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

            #pragma shader_feature_local _GRASSDISPLACEMENT

            #pragma shader_feature_local _ALPHATEST_ON
            #define _SPECULAR_SETUP 1
            #pragma shader_feature _NORMALMAP
            #pragma shader_feature _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature _ENVIRONMENTREFLECTIONS_OFF
            #pragma shader_feature _RECEIVE_SHADOWS_OFF
            #pragma shader_feature_local_fragment _RECEIVESSAO

            #pragma shader_feature_local _WIND_MATH

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
            #include "Includes/ATG URP Foliage Inputs.hlsl"
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

            //  Wind in ObjectSpace, returns WS -------------------------------
            //  Returns position, normal and tangent in WS!
                half4 instanceColor = 0;
                animateVertex(input.color, input.normalOS.xyz, input.tangentOS.xyz, input.positionOS.xyz, instanceColor);
                output.color = instanceColor;
            //  End Wind -------------------------------

                VertexPositionInputs vertexInput; // = GetVertexPositionInputs(input.positionOS.xyz);
                //vertexInput.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                vertexInput.positionWS = input.positionOS.xyz;
                
                VertexNormalInputs normalInput; // = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                normalInput.normalWS = input.normalOS;
                normalInput.tangentWS = input.tangentOS.xyz;

            //  We have to recalculate ClipPos! / see: GetVertexPositionInputs in Core.hlsl
                vertexInput.positionVS = TransformWorldToView(vertexInput.positionWS);
                vertexInput.positionCS = TransformWorldToHClip(vertexInput.positionWS);
                float4 ndc = vertexInput.positionCS * 0.5f;
                vertexInput.positionNDC.xy = float2(ndc.x, ndc.y * _ProjectionParams.x) + ndc.w;
                vertexInput.positionNDC.zw = vertexInput.positionCS.zw;

                half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);
                half fogFactor = ComputeFogFactor(vertexInput.positionCS.z);

                output.uv.xy = input.texcoord;

                #ifdef _NORMALMAP
                    output.normalWS = normalInput.normalWS;
                    real sign = input.tangentOS.w * GetOddNegativeScale();
                    output.tangentWS = half4(normalInput.tangentWS, sign);
                #else
                    output.normalWS = normalInput.normalWS;
                #endif

                OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
                
                #if defined(_NORMALMAP)
                    OUTPUT_SH(output.normalWS.xyz, output.vertexSH);
                #else
            //  TODO: When no normal map is applied we have to lookup SH fully per pixel
                    #if !defined(LIGHTMAP_ON)
                        output.vertexSH = 0;
                    #endif
                #endif
                
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

            inline void InitializeFoliageLitSurfaceData(float2 uv, out SurfaceDescription outSurfaceData)
            {
                half4 albedoAlpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_MainTex, sampler_MainTex));
            //  Early out
                outSurfaceData.alpha = Alpha(albedoAlpha.a, 1, _Cutoff);
                
                outSurfaceData.albedo = albedoAlpha.rgb;
                outSurfaceData.metallic = 0;
                outSurfaceData.specular = _SpecColor;
            
            //  Normal Map
                #if defined (_NORMALMAP)
                    float4 sampleNormal = SAMPLE_TEXTURE2D(_BumpSpecMap, sampler_BumpSpecMap, uv);
                    float3 tangentNormal;
                    tangentNormal.xy = sampleNormal.ag * 2 - 1;
                    tangentNormal.z = sqrt(1.0 - dot(tangentNormal.xy, tangentNormal.xy));  
                    outSurfaceData.normalTS = tangentNormal;
                    outSurfaceData.smoothness = sampleNormal.b * _Smoothness;
                    outSurfaceData.translucency = sampleNormal.r;
                #else
                    outSurfaceData.normalTS = float3(0, 0, 1);
                    outSurfaceData.smoothness = _Smoothness;
                    outSurfaceData.translucency = 1;
                #endif
                outSurfaceData.occlusion = 1;
                outSurfaceData.emission = 0;
            }

            void InitializeInputData(VertexOutput input, half3 normalTS, half facing, out InputData inputData)
            {
                inputData = (InputData)0;
                #if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
                    inputData.positionWS = input.positionWS;
                #endif
                
                half3 viewDirWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
                #ifdef _NORMALMAP
                    normalTS.z *= facing;
                    half sgn = input.tangentWS.w;
                    half3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
                    inputData.normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, bitangent, input.normalWS.xyz));
                #else
                    inputData.normalWS = input.normalWS * facing;
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
                
            //  
                #if defined(_NORMALMAP) 
                    inputData.bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, inputData.normalWS);
                #endif

            //  TODO: Using VFACE and vertex normals – so we should sample SH fully per pixel
                #if !defined(_NORMALMAP) && !defined(LIGHTMAP_ON)
                    inputData.bakedGI = SampleSH(inputData.normalWS);
                #endif

                inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
                inputData.shadowMask = SAMPLE_SHADOWMASK(input.lightmapUV);
            }

            half4 LitPassFragment(VertexOutput input, half facing : VFACE) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

            //  Get the surface description
                SurfaceDescription surfaceData;
                InitializeFoliageLitSurfaceData(input.uv.xy, surfaceData);

            //  Apply color variation
                surfaceData.albedo *= input.color.rgb;

            //  Prepare surface data (like bring normal into world space (incl. VFACE)) and get missing inputs like gi
                InputData inputData;
                InitializeInputData(input, surfaceData.normalTS, facing, inputData);

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
                    1,                  //_AmbientReflection
                    _SSAOStrength       //_SSAOStrength
                );

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
            Cull [_Cull]

            HLSLPROGRAM
            #pragma target 3.0

            #define ISSHADOWPASS

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _VSPSETUP

            #pragma shader_feature_local _GRASSDISPLACEMENT
            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature_local _WIND_MATH


            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma instancing_options assumeuniformscaling procedural:setup

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

        //  Include base inputs and all other needed "base" includes
            #include "Includes/ATG URP Foliage Inputs.hlsl"
            #include "Includes/ATG Instanced Indirect Inputs.hlsl"

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            
        //  Shadow caster specific input
            float3 _LightDirection;

            VertexOutput ShadowPassVertex(VertexInput input)
            {
                VertexOutput output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                output.uv = input.texcoord;

            //  Wind in Object Space, returns WS -------------------------------
                half4 instanceColor = 0;
                half3 tangent = half3(0,0,0);
                animateVertex(input.color, input.normalOS.xyz, tangent, input.positionOS.xyz, instanceColor);
            //  End Wind -------------------------------

                float3 positionWS = input.positionOS.xyz; //TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = input.normalOS; //TransformObjectToWorldDir(input.normalOS);

                output.positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));
                #if UNITY_REVERSED_Z
                    output.positionCS.z = min(output.positionCS.z, output.positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #else
                    output.positionCS.z = max(output.positionCS.z, output.positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #endif
                return output;
            }

            half4 ShadowPassFragment(VertexOutput IN) : SV_TARGET
            {
                #if defined(_ALPHATEST_ON)
                    half alpha = SampleAlbedoAlpha(IN.uv, TEXTURE2D_ARGS(_MainTex, sampler_MainTex)).a;
                    clip(alpha - _Cutoff);
                #endif
                return 0;
            }
            ENDHLSL
        }

    //  Depth -----------------------------------------------------
        Pass
        {
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ColorMask 0
            Cull Off

            HLSLPROGRAM
            #pragma target 3.0

            #define ISDEPTHPASS

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _VSPSETUP

            #pragma shader_feature_local _GRASSDISPLACEMENT
            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature_local _WIND_MATH

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma instancing_options assumeuniformscaling procedural:setup

            #define DEPTHONLYPASS
            #include "Includes/ATG URP Foliage Inputs.hlsl"
            #include "Includes/ATG Instanced Indirect Inputs.hlsl"

            VertexOutput DepthOnlyVertex(VertexInput input)
            {
                VertexOutput output = (VertexOutput)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

            //  Wind in Object Space, returns WS -------------------------------
                half4 instanceColor = 0;
                half3 tangent = half3(0,0,0);
                animateVertex(input.color, input.normalOS.xyz, tangent, input.positionOS.xyz, instanceColor);
            //  End Wind -------------------------------

                VertexPositionInputs vertexInput;
                vertexInput.positionWS = input.positionOS.xyz; //TransformObjectToWorld(input.positionOS.xyz);
                vertexInput.positionCS = TransformWorldToHClip(vertexInput.positionWS);

            //  End Wind -------------------------------                

                output.uv.xy = input.texcoord;
                output.positionCS = vertexInput.positionCS;
                return output;
            }

            half4 DepthOnlyFragment(VertexOutput IN) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN);
                #if defined(_ALPHATEST_ON)
                    half alpha = SampleAlbedoAlpha(IN.uv.xy, TEXTURE2D_ARGS(_MainTex, sampler_MainTex)).a;
                    clip(alpha - _Cutoff);
                #endif
                return 0;
            }

            ENDHLSL
        }


    //  DeptNormals -----------------------------------------------------
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

            #pragma shader_feature_local _GRASSDISPLACEMENT
            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature_local _WIND_MATH

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma instancing_options assumeuniformscaling procedural:setup

            #define DEPTHNORMALPASS
            #include "Includes/ATG URP Foliage Inputs.hlsl"
            #include "Includes/ATG Instanced Indirect Inputs.hlsl"

            VertexOutput DepthNormalsVertex(VertexInput input)
            {
                VertexOutput output = (VertexOutput)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

            //  Wind in Object Space, returns WS -------------------------------
                half4 instanceColor = 0;
                half3 tangent = half3(0,0,0);
                animateVertex(input.color, input.normalOS.xyz, tangent, input.positionOS.xyz, instanceColor);
            //  End Wind -------------------------------

                VertexPositionInputs vertexInput;
                vertexInput.positionWS = input.positionOS.xyz; //TransformObjectToWorld(input.positionOS.xyz);
                vertexInput.positionCS = TransformWorldToHClip(vertexInput.positionWS);
            //  End Wind -------------------------------
                //VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                output.normalWS = input.normalOS; //normalInput.normalWS;

                output.uv.xy = input.texcoord;
                output.positionCS = vertexInput.positionCS;
                return output;
            }

            half4 DepthNormalsFragment(VertexOutput input) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                #if defined(_ALPHATEST_ON)
                    half alpha = SampleAlbedoAlpha(input.uv.xy, TEXTURE2D_ARGS(_MainTex, sampler_MainTex)).a;
                    clip(alpha - _Cutoff);
                #endif
                return float4(PackNormalOctRectEncode(TransformWorldToViewDir(input.normalWS, true)), 0.0, 0.0);
            }

            ENDHLSL
        }

    //  Meta -----------------------------------------------------
        
        Pass
        {
            Tags{"LightMode" = "Meta"}

            Cull Off

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles

            #pragma vertex UniversalVertexMeta
            #pragma fragment UniversalFragmentMeta

            #define _SPECULAR_SETUP
            #define _ALPHATEST_ON 1

        //  First include all our custom stuff
            #include "Includes/ATG URP Foliage Inputs.hlsl"

        //--------------------------------------
        //  Fragment shader and functions

            inline void InitializeStandardLitSurfaceData(float2 uv, out SurfaceData outSurfaceData)
            {
                outSurfaceData = (SurfaceData)0;
                half4 albedoAlpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_MainTex, sampler_MainTex));
                outSurfaceData.alpha = Alpha(albedoAlpha.a, 1, _Cutoff);
                outSurfaceData.albedo = albedoAlpha.rgb;
                outSurfaceData.metallic = 0;
                outSurfaceData.specular = _SpecColor;
                outSurfaceData.smoothness = _Smoothness;
                outSurfaceData.normalTS = half3(0,0,1); //SampleNormal(uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap));
                outSurfaceData.occlusion = 1;
                outSurfaceData.emission = 0;
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
