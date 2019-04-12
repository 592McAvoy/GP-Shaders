using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System;

public class CustomShaderGUI : ShaderGUI
{
    MaterialEditor editor;
    MaterialProperty[] properties;
    Material target;

    enum ShaderType
    {
        PureColor, Normal_Only, Texture_Only, Blinn_Phong
    }
    enum SpecularChoice
    {
        True, False
    }

    public override void OnGUI(MaterialEditor editor, MaterialProperty[] properties)
    {
        this.editor = editor;
        this.properties = properties;
        this.target = editor.target as Material;

        ShaderType shaderType = ShaderType.PureColor;

        if (target.IsKeywordEnabled("PURE_COLOR"))
        {
            shaderType = ShaderType.PureColor;
        }
        else if (target.IsKeywordEnabled("NORMAL_ONLY"))
        {
            shaderType = ShaderType.Normal_Only;
        }
        else if (target.IsKeywordEnabled("TEXTURE_ONLY"))
        {
            shaderType = ShaderType.Texture_Only;
        }
        else
        {
            shaderType = ShaderType.Blinn_Phong;
        }

        EditorGUI.BeginChangeCheck();
        shaderType = (ShaderType)EditorGUILayout.EnumPopup(
            new GUIContent("Shader Type: "), shaderType
        );

        if (EditorGUI.EndChangeCheck())
        {
            if (shaderType == ShaderType.PureColor)
            {
                target.DisableKeyword("NORMAL_ONLY");
                target.DisableKeyword("TEXTURE_ONLY");
                target.DisableKeyword("BLINN_PHONG");
                target.EnableKeyword("PURE_COLOR");
            }
            else if (shaderType == ShaderType.Normal_Only)
            {
                target.DisableKeyword("PURE_COLOR");
                target.DisableKeyword("TEXTURE_ONLY");
                target.DisableKeyword("BLINN_PHONG");
                target.EnableKeyword("NORMAL_ONLY");
            }
            else if (shaderType == ShaderType.Texture_Only)
            {
                target.DisableKeyword("PURE_COLOR");
                target.DisableKeyword("NORMAL_ONLY");
                target.DisableKeyword("BLINN_PHONG");
                target.EnableKeyword("TEXTURE_ONLY");
            }
            else
            {
                target.DisableKeyword("PURE_COLOR");
                target.DisableKeyword("NORMAL_ONLY");
                target.DisableKeyword("TEXTURE_ONLY");
                target.EnableKeyword("BLINN_PHONG");
            }
        }

        if (shaderType == ShaderType.PureColor)
        {
            OnPureColor();
        }
        else if (shaderType == ShaderType.Normal_Only)
        {
            OnNormalOnly();
        }
        else if (shaderType == ShaderType.Texture_Only)
        {
            OnTextureOnly();
        }
        else
        {
            OnBlinnPhong();
        }
    }

    void OnPureColor()
    {
        MaterialProperty mainColor = FindProperty("_MainColor", properties);
        GUIContent mainColorLabel = new GUIContent(mainColor.displayName);
        editor.ColorProperty(mainColor, mainColorLabel.text);
          
    }

    void OnNormalOnly()
    {
        
    }

    void OnTextureOnly()
    {
        MaterialProperty mainTex = FindProperty("_MainTex", properties);
        GUIContent mainTexLabel = new GUIContent(mainTex.displayName);
        editor.TextureProperty(mainTex, mainTexLabel.text);
    }

    void OnBlinnPhong()
    {
        MaterialProperty mainTex = FindProperty("_MainTex", properties);
        GUIContent mainTexLabel = new GUIContent(mainTex.displayName);
        editor.TextureProperty(mainTex, mainTexLabel.text);

        SpecularChoice specularChoice = SpecularChoice.False;
        if (target.IsKeywordEnabled("USE_SPECULAR"))
            specularChoice = SpecularChoice.True;

        EditorGUI.BeginChangeCheck();
        specularChoice = (SpecularChoice)EditorGUILayout.EnumPopup(
            new GUIContent("Use Specular?"), specularChoice
        );

        if (EditorGUI.EndChangeCheck())
        {
            if (specularChoice == SpecularChoice.True)
                target.EnableKeyword("USE_SPECULAR");

            else
                target.DisableKeyword("USE_SPECULAR");
        }

        if (specularChoice == SpecularChoice.True)
        {
            MaterialProperty shininess = FindProperty("_Shininess", properties);
            GUIContent shininessLabel = new GUIContent(shininess.displayName);
            editor.FloatProperty(shininess, "Specular Factor");
        }
    }
}
