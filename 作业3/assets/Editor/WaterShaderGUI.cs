using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System;

public class WaterShaderGUI : ShaderGUI
{
    MaterialEditor editor;
    MaterialProperty[] properties;
    Material target;

    enum WaveChoice
    {
        True, False
    }
    enum RampTextureChoice
    {
        True, False
    }

    public override void OnGUI(MaterialEditor editor, MaterialProperty[] properties)
    {
        this.editor = editor;
        this.properties = properties;
        this.target = editor.target as Material;

        WaveChoice waveChoice = WaveChoice.False;
        RampTextureChoice rampTextureChoice = RampTextureChoice.False;

        if (target.IsKeywordEnabled("RAMP_TEX"))
        {
            rampTextureChoice = RampTextureChoice.True;
        }
        if (target.IsKeywordEnabled("USE_WAVE"))
        {
            waveChoice = WaveChoice.True;
        }

        BasicUI();

        EditorGUI.BeginChangeCheck();
        waveChoice = (WaveChoice)EditorGUILayout.EnumPopup(
            new GUIContent("Enable wave? "), waveChoice
        );

        if (EditorGUI.EndChangeCheck())
        {
            if(waveChoice == WaveChoice.True)
            {
                target.EnableKeyword("USE_WAVE");
            }
            else
            {
                target.DisableKeyword("USE_WAVE");
            }            
        }

        if (waveChoice == WaveChoice.True)
        {
            OnUseWave();
        }


        EditorGUI.BeginChangeCheck();
        rampTextureChoice = (RampTextureChoice)EditorGUILayout.EnumPopup(
            new GUIContent("Use Ramp Texture? "), rampTextureChoice
        );

        if (EditorGUI.EndChangeCheck())
        {
            if (rampTextureChoice == RampTextureChoice.True)
            {
                target.EnableKeyword("RAMP_TEX");
            }
            else
            {
                target.DisableKeyword("RAMP_TEX");
            }
        }

        if (rampTextureChoice == RampTextureChoice.True)
        {
            OnRampTexture();
        }
    }

    void BasicUI()
    {
        MaterialProperty mainTex = FindProperty("_MainTex", properties);
        GUIContent mainTexLabel = new GUIContent(mainTex.displayName);
        editor.TextureProperty(mainTex, mainTexLabel.text);

        MaterialProperty color = FindProperty("_Color", properties);
        GUIContent colorLabel = new GUIContent(color.displayName);
        editor.ColorProperty(color, colorLabel.text);

        MaterialProperty edgeColor = FindProperty("_EdgeColor", properties);
        GUIContent edgeColorLabel = new GUIContent(edgeColor.displayName);
        editor.ColorProperty(edgeColor, edgeColorLabel.text);

        MaterialProperty depthFactor = FindProperty("_DepthFactor", properties);
        GUIContent depthFactorLabel = new GUIContent(depthFactor.displayName);
        editor.FloatProperty(depthFactor, depthFactorLabel.text);

        MaterialProperty distortStrength = FindProperty("_DistortStrength", properties);
        GUIContent distortStrengthLabel = new GUIContent(distortStrength.displayName);
        editor.FloatProperty(distortStrength, distortStrengthLabel.text);
    }

    void OnUseWave()
    {
        MaterialProperty noiseTex = FindProperty("_NoiseTex", properties);
        GUIContent noiseTexLabel = new GUIContent(noiseTex.displayName);
        editor.TextureProperty(noiseTex, noiseTexLabel.text);

        MaterialProperty waveSpeed = FindProperty("_WaveSpeed", properties);
        GUIContent waveSpeedLabel = new GUIContent(waveSpeed.displayName);
        editor.FloatProperty(waveSpeed, waveSpeedLabel.text);

        MaterialProperty waveAmp = FindProperty("_WaveAmp", properties);
        GUIContent waveAmpLabel = new GUIContent(waveAmp.displayName);
        editor.FloatProperty(waveAmp, waveAmpLabel.text);

        MaterialProperty extraHeight = FindProperty("_ExtraHeight", properties);
        GUIContent extraHeightLabel = new GUIContent(extraHeight.displayName);
        editor.FloatProperty(extraHeight, extraHeightLabel.text);
    }

    void OnRampTexture()
    {
        MaterialProperty rampTex = FindProperty("_DepthRampTex", properties);
        GUIContent rampTexLabel = new GUIContent(rampTex.displayName);
        editor.TextureProperty(rampTex, rampTexLabel.text);
    }
}
