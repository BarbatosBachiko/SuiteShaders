/*------------------.
| :: Description :: |
'-------------------/

  ColorSuite
 
  Version: 1.0
  Author: Barbatos Bachiko
  About: Provides a complete set of tools for color correction and artistic effects.
  Includes brightness, contrast, HSL, color balance, scene tint, posterize, invert, color replace, gradient map, and edge detection.
 */

#include "ReShade.fxh"

/*---------
| :: UI :: |
'---------*/

// Basic
uniform float Brightness <
    ui_category = "Basic Adjustments";
    ui_type = "drag";
    ui_label = "Brightness";
    ui_tooltip = "Adjusts the overall brightness of the image.";
    ui_min = -0.350;
    ui_max = 0.330;
    ui_step = 0.005;
> = 0.0;

uniform float Contrast <
    ui_category = "Basic Adjustments";
    ui_type = "slider";
    ui_label = "Contrast";
    ui_tooltip = "Adjusts the difference between light and dark areas.";
    ui_min = 0.0;
    ui_max = 1.7;
    ui_step = 0.01;
> = 1.0;

// Color Grading (HSL)
uniform float Hue <
    ui_category = "Color Grading";
    ui_type = "slider";
    ui_label = "Hue Shift";
    ui_tooltip = "Rotates the hue of all colors.";
    ui_min = -180.0;
    ui_max = 180.0;
    ui_step = 0.1;
> = 0.0;

uniform float Saturation <
    ui_category = "Color Grading";
    ui_type = "slider";
    ui_label = "Saturation";
    ui_tooltip = "Controls the intensity of all colors.";
    ui_min = 0.0;
    ui_max = 2.0;
    ui_step = 0.01;
> = 1.0;

uniform float Lightness <
    ui_category = "Color Grading";
    ui_type = "slider";
    ui_label = "Lightness";
    ui_tooltip = "Adjusts the lightness of colors without affecting pure black or white.";
    ui_min = -1.0;
    ui_max = 1.0;
    ui_step = 0.01;
> = 0.0;

// Color Balance
uniform float3 ColorBalance_Shadows <
    ui_category = "Color Balance";
    ui_type = "color";
    ui_label = "Shadows Tint";
> = float3(0.5, 0.5, 0.5);

uniform float3 ColorBalance_Midtones <
    ui_category = "Color Balance";
    ui_type = "color";
    ui_label = "Midtones Tint";
> = float3(0.5, 0.5, 0.5);

uniform float3 ColorBalance_Highlights <
    ui_category = "Color Balance";
    ui_type = "color";
    ui_label = "Highlights Tint";
> = float3(0.5, 0.5, 0.5);

// Artistic Effects
uniform int ArtisticMode <
    ui_category = "Artistic Effects";
    ui_type = "combo";
    ui_label = "Effect Mode";
    ui_items = "None\0Line Drawing\0Calligraphy\0Edge Detection\0";
> = 0;

uniform float EdgeThreshold <
    ui_category = "Artistic Effects";
    ui_type = "slider";
    ui_label = "Edge Detection Threshold";
    ui_min = 0.0;
    ui_max = 1.0;
> = 0.5;

uniform float EdgeSmoothing <
    ui_category = "Artistic Effects";
    ui_type = "slider";
    ui_label = "Edge Smoothing";
    ui_tooltip = "Controls the softness and anti-aliasing of the detected lines.";
    ui_min = 0.01;
    ui_max = 0.5;
> = 0.5;

// Image Effects
uniform bool InvertColor <
    ui_category = "Image Effects";
    ui_type = "checkbox";
    ui_label = "Invert Color";
> = false;

uniform int PosterizeLevels <
    ui_category = "Image Effects";
    ui_type = "slider";
    ui_label = "Posterize Levels";
    ui_min = 2;
    ui_max = 256;
> = 256;

// Gradient Map
uniform bool EnableGradMap <
    ui_category = "Gradient Map";
    ui_type = "checkbox";
    ui_label = "Enable Gradient Map";
    ui_tooltip = "Maps image luminance to a custom gradient. Overrides most other color settings.";
> = false;

uniform float3 GradMap_Start <
    ui_category = "Gradient Map";
    ui_type = "color";
    ui_label = "Gradient Start (Shadows)";
> = float3(1.0, 0.0, 0.0);

uniform float3 GradMap_End <
    ui_category = "Gradient Map";
    ui_type = "color";
    ui_label = "Gradient End (Highlights)";
> = float3(0.0, 0.0, 1.0);

// Color Replace
uniform bool EnableColorReplace <
    ui_category = "Color Replace";
    ui_type = "checkbox";
    ui_label = "Enable Color Replace";
> = false;

uniform float3 ColorReplace_Target <
    ui_category = "Color Replace";
    ui_type = "color";
    ui_label = "Target Color";
> = float3(0.0, 1.0, 0.0);

uniform float3 ColorReplace_New <
    ui_category = "Color Replace";
    ui_type = "color";
    ui_label = "New Color";
> = float3(1.0, 0.0, 0.0);

uniform float ColorReplace_Tolerance <
    ui_category = "Color Replace";
    ui_type = "slider";
    ui_label = "Tolerance";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.01;
> = 0.8;

// Scene Tint
uniform float3 SceneTintColor <
    ui_category = "Scene Tint";
    ui_type = "color";
    ui_label = "Environment Color";
> = float3(1.0, 0.8, 0.6);

uniform float SceneTintAmount <
    ui_category = "Scene Tint";
    ui_type = "slider";
    ui_label = "Tint Amount";
    ui_min = 0.0;
    ui_max = 1.0;
> = 0.0;

/*---------------
| :: Functions ::|
'---------------*/

static const float3 LumaCoeff = float3(0.2126, 0.7152, 0.0722);
float GetLuminance(float3 color)
{
    return dot(color, LumaCoeff);
}

float3 RgbToHsl(float3 color)
{
    float max_val = max(color.r, max(color.g, color.b)), min_val = min(color.r, min(color.g, color.b));
    float h = 0.0, s = 0.0, l = (max_val + min_val) / 2.0;
    if (max_val != min_val)
    {
        float d = max_val - min_val;
        s = l > 0.5 ? d / (2.0 - max_val - min_val) : d / (max_val + min_val);
        if (max_val == color.r)
            h = (color.g - color.b) / d + (color.g < color.b ? 6.0 : 0.0);
        else if (max_val == color.g)
            h = (color.b - color.r) / d + 2.0;
        else if (max_val == color.b)
            h = (color.r - color.g) / d + 4.0;
        h /= 6.0;
    }
    return float3(h, s, l);
}

float HueToRgb(float p, float q, float t)
{
    if (t < 0.0)
        t += 1.0;
    if (t > 1.0)
        t -= 1.0;
    if (t < 1.0 / 6.0)
        return p + (q - p) * 6.0 * t;
    if (t < 1.0 / 2.0)
        return q;
    if (t < 2.0 / 3.0)
        return p + (q - p) * (2.0 / 3.0 - t) * 6.0;
    return p;
}

float3 HslToRgb(float3 hsl)
{
    if (hsl.y == 0.0)
        return hsl.z.xxx;
    float q = hsl.z < 0.5 ? hsl.z * (1.0 + hsl.y) : hsl.z + hsl.y - hsl.z * hsl.y;
    float p = 2.0 * hsl.z - q;
    return float3(HueToRgb(p, q, hsl.x + 1.0 / 3.0), HueToRgb(p, q, hsl.x), HueToRgb(p, q, hsl.x - 1.0 / 3.0));
}

float3 ApplyColorBalance(float3 color, float3 shadows, float3 midtones, float3 highlights)
{
    float luma = GetLuminance(color);
    float shadowMask = smoothstep(0.5, 0.0, luma);
    float highlightMask = smoothstep(0.5, 1.0, luma);
    float midtoneMask = 1.0 - shadowMask - highlightMask;
    float3 balancedColor = color;
    balancedColor += shadowMask * (shadows - 0.5);
    balancedColor += midtoneMask * (midtones - 0.5);
    balancedColor += highlightMask * (highlights - 0.5);

    return balancedColor;
}

float3 EdgeDetectionPass(float2 texcoord, float threshold, int mode, float smoothing)
{
    float2 px = ReShade::PixelSize;

    float l_nw = GetLuminance(tex2D(ReShade::BackBuffer, texcoord - px).rgb);
    float l_n = GetLuminance(tex2D(ReShade::BackBuffer, texcoord + float2(0, -px.y)).rgb);
    float l_ne = GetLuminance(tex2D(ReShade::BackBuffer, texcoord + float2(px.x, -px.y)).rgb);
    float l_w = GetLuminance(tex2D(ReShade::BackBuffer, texcoord + float2(-px.x, 0)).rgb);
    float l_e = GetLuminance(tex2D(ReShade::BackBuffer, texcoord + float2(px.x, 0)).rgb);
    float l_sw = GetLuminance(tex2D(ReShade::BackBuffer, texcoord + float2(-px.x, px.y)).rgb);
    float l_s = GetLuminance(tex2D(ReShade::BackBuffer, texcoord + float2(0, px.y)).rgb);
    float l_se = GetLuminance(tex2D(ReShade::BackBuffer, texcoord + px).rgb);

    float Gx = (l_ne + 2.0 * l_e + l_se) - (l_nw + 2.0 * l_w + l_sw);
    float Gy = (l_sw + 2.0 * l_s + l_se) - (l_nw + 2.0 * l_n + l_ne);
    float edge = length(float2(Gx, Gy));
    
    switch (mode)
    {
        case 1: // Anti-aliased lines
            return 1.0 - smoothstep(threshold - smoothing, threshold + smoothing, edge);
        case 2: // Thicker
            return 1.0 - smoothstep(threshold - smoothing * 1.5, threshold + smoothing * 1.5, edge);
        case 3: // Edge Detection
            return edge > threshold ? 0.0 : 1.0;
    }

    return 1.0;
}

/*------------------
| :: Pixel Shader ::|
'------------------*/

float4 ColorSuite(float4 pos : SV_Position, float2 texcoord : TexCoord) : SV_Target
{
    // Artistic line modes
    if (ArtisticMode > 0)
    {
        float3 effectColor = EdgeDetectionPass(texcoord, EdgeThreshold, ArtisticMode, EdgeSmoothing);
        return float4(effectColor, 1.0);
    }
    float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;

    // Brightness and Contrast
    color = (color - 0.5) * Contrast + 0.5 + Brightness;

    // Color Balance
    if (!all(ColorBalance_Shadows == 0.5) || !all(ColorBalance_Midtones == 0.5) || !all(ColorBalance_Highlights == 0.5))
    {
        color = ApplyColorBalance(color, ColorBalance_Shadows, ColorBalance_Midtones, ColorBalance_Highlights);
    }

    // HSL
    if (Hue != 0.0 || Saturation != 1.0 || Lightness != 0.0)
    {
        float3 hsl = RgbToHsl(color);
        hsl.x = frac(hsl.x + Hue / 360.0);
        hsl.y *= Saturation;
        hsl.z += Lightness;
        color = HslToRgb(saturate(hsl));
    }
    
    // Posterize
    if (PosterizeLevels < 256)
    {
        color = floor(color * PosterizeLevels) / PosterizeLevels;
    }

    // Color Replace
    if (EnableColorReplace)
    {
        float dist = distance(color, ColorReplace_Target);
        float replace_lerp = smoothstep(ColorReplace_Tolerance, ColorReplace_Tolerance * 0.8, dist);
        color = lerp(color, ColorReplace_New, replace_lerp);
    }

    // Scene Tint
    if (SceneTintAmount > 0.0)
    {
        color = lerp(color, color * SceneTintColor, SceneTintAmount);
    }
    
    // Gradient Map 
    if (EnableGradMap)
    {
        float luma = GetLuminance(saturate(color));
        color = lerp(GradMap_Start, GradMap_End, luma);
    }

    // Invert Color 
    if (InvertColor)
    {
        color = 1.0 - color;
    }

    return float4(saturate(color), 1.0);
}

technique ColorSuite
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = ColorSuite;
    }
}
