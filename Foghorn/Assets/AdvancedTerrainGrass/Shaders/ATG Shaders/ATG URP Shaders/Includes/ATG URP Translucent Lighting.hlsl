#ifndef ATGURP_TRANSLUCENTLIGHTING_INCLUDED
#define ATGURP_TRANSLUCENTLIGHTING_INCLUDED


half3 GlobalIllumination_Lux(BRDFData brdfData, half3 bakedGI, half occlusion, half3 normalWS, half3 viewDirectionWS, 
    half specOccluison)
{
    half3 reflectVector = reflect(-viewDirectionWS, normalWS);
    half fresnelTerm = Pow4(1.0 - saturate(dot(normalWS, viewDirectionWS)));

    half3 indirectDiffuse = bakedGI * occlusion;
    half3 indirectSpecular = GlossyEnvironmentReflection(reflectVector, brdfData.perceptualRoughness, occlusion)        * specOccluison;

    return EnvironmentBRDF(brdfData, indirectDiffuse, indirectSpecular, fresnelTerm);
}


half3 LightingPhysicallyBasedWrapped(BRDFData brdfData, half3 lightColor, half3 lightDirectionWS, half lightAttenuation, half3 normalWS, half3 viewDirectionWS, half NdotL)
{
    half3 radiance = lightColor * (lightAttenuation * NdotL);
    //return DirectBDRF_Lux(brdfData, normalWS, lightDirectionWS, viewDirectionWS) * radiance;
    return DirectBDRF(brdfData, normalWS, lightDirectionWS, viewDirectionWS) * radiance;
}

half3 LightingPhysicallyBasedWrapped(BRDFData brdfData, Light light, half3 normalWS, half3 viewDirectionWS, half NdotL)
{
    return LightingPhysicallyBasedWrapped(brdfData, light.color, light.direction, light.distanceAttenuation * light.shadowAttenuation, normalWS, viewDirectionWS, NdotL);
}



half4 ATGURPTranslucentFragmentPBR(InputData inputData, half3 albedo, half metallic, half3 specular,
    half smoothness, half occlusion, half3 emission, half alpha, half4 translucency, half AmbientReflection, half SSAOStrength
    #if defined(_CUSTOMWRAP)
        , half wrap
    #endif
    #if defined(_STANDARDLIGHTING)
        , half mask
    #endif
)
{
    BRDFData brdfData;
    InitializeBRDFData(albedo, metallic, specular, smoothness, alpha, brdfData);

//  ShadowMask: To ensure backward compatibility we have to avoid using shadowMask input, as it is not present in older shaders
    #if defined(SHADOWS_SHADOWMASK) && defined(LIGHTMAP_ON)
        half4 shadowMask = inputData.shadowMask;
    #elif !defined (LIGHTMAP_ON)
        half4 shadowMask = unity_ProbesOcclusion;
    #else
        half4 shadowMask = half4(1, 1, 1, 1);
    #endif

    //Light mainLight = GetMainLight(inputData.shadowCoord);
    Light mainLight = GetMainLight(inputData.shadowCoord, inputData.positionWS, shadowMask);
//  SSAO
    #if defined(_SCREEN_SPACE_OCCLUSION) && defined(_RECEIVESSAO)
        AmbientOcclusionFactor aoFactor = GetScreenSpaceAmbientOcclusion(inputData.normalizedScreenSpaceUV);
        aoFactor.directAmbientOcclusion = lerp(1, aoFactor.directAmbientOcclusion, SSAOStrength);
        aoFactor.indirectAmbientOcclusion = lerp(1, aoFactor.indirectAmbientOcclusion, SSAOStrength);
        mainLight.color *= aoFactor.directAmbientOcclusion;
        occlusion = min(occlusion, aoFactor.indirectAmbientOcclusion);
    #endif

    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, half4(0, 0, 0, 0));

    half3 color = GlobalIllumination_Lux(brdfData, inputData.bakedGI, occlusion, inputData.normalWS, inputData.viewDirectionWS,     AmbientReflection);

//  Wrapped Diffuse
    #if defined(_CUSTOMWRAP)
        half w = wrap;
        #if defined(_STANDARDLIGHTING)
             w *= mask;
        #endif
    #else
        half w = 0.4;
    #endif
    //half NdotL = saturate((dot(inputData.normalWS, mainLight.direction) + w) / ((1 + w) * (1 + w)));
    half NdotL = saturate( dot(inputData.normalWS, mainLight.direction) );
    color += LightingPhysicallyBasedWrapped(brdfData, mainLight, inputData.normalWS, inputData.viewDirectionWS, NdotL);

//  translucency
    half transPower = translucency.y;
    half3 transLightDir = mainLight.direction + inputData.normalWS * translucency.w;
    half transDot = dot( transLightDir, -inputData.viewDirectionWS );
    transDot = exp2(saturate(transDot) * transPower - transPower);
    color += brdfData.diffuse * transDot * (1.0 - NdotL) * mainLight.color * lerp(1.0h, mainLight.shadowAttenuation, translucency.z) * translucency.x * 4
    #if defined(_STANDARDLIGHTING)
        * mask
    #endif
    ;


    #ifdef _ADDITIONAL_LIGHTS
        uint pixelLightCount = GetAdditionalLightsCount();
        for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
        {
            Light light = GetAdditionalLight(lightIndex, inputData.positionWS, shadowMask);
    //  Wrapped Diffuse
            //NdotL = saturate((dot(inputData.normalWS, light.direction) + w) / ((1 + w) * (1 + w)));
            half NdotL = saturate( dot(inputData.normalWS, light.direction) );
            color += LightingPhysicallyBasedWrapped(brdfData, light, inputData.normalWS, inputData.viewDirectionWS, NdotL);

    //  Translucency
            transLightDir = light.direction + inputData.normalWS * translucency.w;
            transDot = dot( transLightDir, -inputData.viewDirectionWS );
            transDot = exp2(saturate(transDot) * transPower - transPower);
            color += brdfData.diffuse * transDot * (1.0 - NdotL) * light.color * lerp(1.0h, light.shadowAttenuation, translucency.z) * light.distanceAttenuation * translucency.x * 4
            #if defined(_STANDARDLIGHTING)
                * mask
            #endif
            ;
        }
    #endif

    #ifdef _ADDITIONAL_LIGHTS_VERTEX
        color += inputData.vertexLighting * brdfData.diffuse;
    #endif

    color += emission;

    return half4(color, alpha);
}
#endif