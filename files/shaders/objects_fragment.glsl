#version 120
#pragma import_defines(FORCE_OPAQUE)

#if @useUBO
    #extension GL_ARB_uniform_buffer_object : require
#endif

#if @useGPUShader4
    #extension GL_EXT_gpu_shader4: require
#endif

#if @diffuseMap
uniform sampler2D diffuseMap;
varying vec2 diffuseMapUV;
#endif

#if @darkMap
uniform sampler2D darkMap;
varying vec2 darkMapUV;
#endif

#if @detailMap
uniform sampler2D detailMap;
varying vec2 detailMapUV;
#endif

#if @decalMap
uniform sampler2D decalMap;
varying vec2 decalMapUV;
#endif

#if @emissiveMap
uniform sampler2D emissiveMap;
varying vec2 emissiveMapUV;
#endif

#if @normalMap
uniform sampler2D normalMap;
varying vec2 normalMapUV;
varying vec4 passTangent;
#endif

#if @envMap
uniform sampler2D envMap;
varying vec2 envMapUV;
uniform vec4 envMapColor;
#endif

#if @specularMap
uniform sampler2D specularMap;
varying vec2 specularMapUV;
#endif

#if @bumpMap
uniform sampler2D bumpMap;
varying vec2 bumpMapUV;
uniform vec2 envMapLumaBias;
uniform mat2 bumpMapMatrix;
#endif

#if @glossMap
uniform sampler2D glossMap;
varying vec2 glossMapUV;
#endif

uniform vec2 screenRes;

#define PER_PIXEL_LIGHTING (@normalMap || @forcePPL)

#if !PER_PIXEL_LIGHTING
centroid varying vec3 passLighting;
centroid varying vec3 shadowDiffuseLighting;
#else
uniform float emissiveMult;
#endif
uniform float specStrength;
varying vec3 passViewPos;
varying vec3 passNormal;

#if @additiveBlending
#define ADDITIVE_BLENDING
#endif

#include "vertexcolors.glsl"
#include "shadows_fragment.glsl"
#include "lighting.glsl"
#include "parallax.glsl"
#include "alpha.glsl"
#include "fog.glsl"

#if @softParticles
#include "softparticles.glsl"
#endif

#if @particleOcclusion
uniform sampler2D orthoDepthMap;

varying vec3 orthoDepthMapCoord;

void precipitationOcclusion()
{
    float sceneDepth = texture2D(orthoDepthMap, orthoDepthMapCoord.xy * 0.5 + 0.5).r;
#if @reverseZ
    if (orthoDepthMapCoord.z < sceneDepth)
        discard;
#else
    if (orthoDepthMapCoord.z * 0.5 + 0.5 > sceneDepth)
        discard;
#endif
}
#endif

void main()
{
#if @particleOcclusion
    precipitationOcclusion();
#endif

#if @diffuseMap
    vec2 adjustedDiffuseUV = diffuseMapUV;
#endif

    vec3 worldNormal = normalize(passNormal);
    vec3 viewVec = normalize(passViewPos.xyz);

#if @normalMap
    vec4 normalTex = texture2D(normalMap, normalMapUV);

    vec3 normalizedNormal = worldNormal;
    vec3 normalizedTangent = normalize(passTangent.xyz);
    vec3 binormal = cross(normalizedTangent, normalizedNormal) * passTangent.w;
    mat3 tbnTranspose = mat3(normalizedTangent, binormal, normalizedNormal);

    worldNormal = normalize(tbnTranspose * (normalTex.xyz * 2.0 - 1.0));
    vec3 viewNormal = gl_NormalMatrix * worldNormal;
#endif

#if (!@normalMap && (@parallax || @forcePPL || @softParticles))
    vec3 viewNormal = gl_NormalMatrix * worldNormal;
#endif

#if @parallax
    vec3 cameraPos = (gl_ModelViewMatrixInverse * vec4(0,0,0,1)).xyz;
    vec3 objectPos = (gl_ModelViewMatrixInverse * vec4(passViewPos, 1)).xyz;
    vec3 eyeDir = normalize(cameraPos - objectPos);
    vec2 offset = getParallaxOffset(eyeDir, tbnTranspose, normalTex.a, (passTangent.w > 0.0) ? -1.f : 1.f);
    adjustedDiffuseUV += offset; // only offset diffuse for now, other textures are more likely to be using a completely different UV set

    // TODO: check not working as the same UV buffer is being bound to different targets
    // if diffuseMapUV == normalMapUV
#if 1
    // fetch a new normal using updated coordinates
    normalTex = texture2D(normalMap, adjustedDiffuseUV);

    worldNormal = normalize(tbnTranspose * (normalTex.xyz * 2.0 - 1.0));
    viewNormal = gl_NormalMatrix * worldNormal;
#endif

#endif

#if @diffuseMap
    gl_FragData[0] = texture2D(diffuseMap, adjustedDiffuseUV);
    gl_FragData[0].a *= coveragePreservingAlphaScale(diffuseMap, adjustedDiffuseUV);
#else
    gl_FragData[0] = vec4(1.0);
#endif

    vec4 diffuseColor = getDiffuseColor();
    gl_FragData[0].a *= diffuseColor.a;

#if @darkMap
    gl_FragData[0] *= texture2D(darkMap, darkMapUV);
    gl_FragData[0].a *= coveragePreservingAlphaScale(darkMap, darkMapUV);
#endif

    alphaTest();

#if @detailMap
    gl_FragData[0].xyz *= texture2D(detailMap, detailMapUV).xyz * 2.0;
#endif

#if @decalMap
    vec4 decalTex = texture2D(decalMap, decalMapUV);
    gl_FragData[0].xyz = mix(gl_FragData[0].xyz, decalTex.xyz, decalTex.a * diffuseColor.a);
#endif

#if @envMap

    vec2 envTexCoordGen = envMapUV;
    float envLuma = 1.0;

#if @normalMap
    // if using normal map + env map, take advantage of per-pixel normals for envTexCoordGen
    vec3 r = reflect( viewVec, viewNormal );
    float m = 2.0 * sqrt( r.x*r.x + r.y*r.y + (r.z+1.0)*(r.z+1.0) );
    envTexCoordGen = vec2(r.x/m + 0.5, r.y/m + 0.5);
#endif

#if @bumpMap
    vec4 bumpTex = texture2D(bumpMap, bumpMapUV);
    envTexCoordGen += bumpTex.rg * bumpMapMatrix;
    envLuma = clamp(bumpTex.b * envMapLumaBias.x + envMapLumaBias.y, 0.0, 1.0);
#endif

    vec3 envEffect = texture2D(envMap, envTexCoordGen).xyz * envMapColor.xyz * envLuma;

#if @glossMap
    envEffect *= texture2D(glossMap, glossMapUV).xyz;
#endif

#if @preLightEnv
    gl_FragData[0].xyz += envEffect;
#endif

#endif

    float shadowing = unshadowedLightRatio(-passViewPos.z);
    vec3 lighting;
#if !PER_PIXEL_LIGHTING
    lighting = passLighting + shadowDiffuseLighting * shadowing;
#else
    vec3 diffuseLight, ambientLight;
    doLighting(passViewPos, normalize(viewNormal), shadowing, diffuseLight, ambientLight);
    vec3 emission = getEmissionColor().xyz * emissiveMult;
    lighting = diffuseColor.xyz * diffuseLight + getAmbientColor().xyz * ambientLight + emission;
#endif

    clampLightingResult(lighting);

    gl_FragData[0].xyz *= lighting;

#if @envMap && !@preLightEnv
    gl_FragData[0].xyz += envEffect;
#endif

#if @emissiveMap
    gl_FragData[0].xyz += texture2D(emissiveMap, emissiveMapUV).xyz;
#endif

#if @specularMap
    vec4 specTex = texture2D(specularMap, specularMapUV);
    float shininess = specTex.a * 255.0;
    vec3 matSpec = specTex.xyz;
#else
    float shininess = gl_FrontMaterial.shininess;
    vec3 matSpec = getSpecularColor().xyz;
#endif

    matSpec *= specStrength;
    if (matSpec != vec3(0.0))
    {
#if (!@normalMap && !@parallax && !@forcePPL)
        vec3 viewNormal = gl_NormalMatrix * worldNormal;
#endif
        gl_FragData[0].xyz += getSpecular(normalize(viewNormal), viewVec, shininess, matSpec) * shadowing;
    }

    gl_FragData[0] = applyFogAtPos(gl_FragData[0], passViewPos);

#if !defined(FORCE_OPAQUE) && @softParticles
    gl_FragData[0].a *= calcSoftParticleFade(viewVec, viewNormal, passViewPos);
#endif

#if defined(FORCE_OPAQUE) && FORCE_OPAQUE
    // having testing & blending isn't enough - we need to write an opaque pixel to be opaque
    gl_FragData[0].a = 1.0;
#endif

#if !defined(FORCE_OPAQUE) && !@disableNormals
    gl_FragData[1].xyz = worldNormal * 0.5 + 0.5;
#endif

    applyShadowDebugOverlay();
}
