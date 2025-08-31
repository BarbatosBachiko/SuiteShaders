/*------------------.
| :: Description :: |
'-------------------/

    BlurSuite

   Version: 1.0
   Author: Barbados

   About: A collection of blur effects for ReShade.
 */

#include "ReShade.fxh"
#include "Blending.fxh"

#define GetColor(coord) tex2Dlod(ReShade::BackBuffer, float4(coord, 0.0, 0.0))

/*-------------------.
| :: Parameters ::   |
'-------------------*/

BLENDING_COMBO(BlurBlendMode, "Blend Mode", "Selects the blending mode for combining the blur with the original image.", "Master Controls", false, 1, 0)

uniform float BlurMix <
    ui_category = "Master Controls";
    ui_type = "slider";
    ui_label = "Mix";
    ui_tooltip = "Controls the amount of the blended blur effect.";
    ui_min = 0.0;
    ui_max = 1.0;
> = 1.0;

//Box Blur 
uniform bool EnableBoxBlur <
    ui_category = "Box Blur";
    ui_type = "checkbox";
    ui_label = "Enable Box Blur";
    ui_tooltip = "A simple and fast blur effect. Good for performance.";
> = false;

uniform float BoxBlurRadius <
    ui_category = "Box Blur";
    ui_type = "slider";
    ui_label = "Radius";
    ui_tooltip = "Controls the spread of the blur.";
    ui_min = 0.0;
    ui_max = 10.0;
    ui_step = 0.01;
> = 1.0;

uniform int BoxBlurSamples <
    ui_category = "Box Blur";
    ui_type = "slider";
    ui_label = "Samples";
    ui_tooltip = "Number of samples for the Box blur. Higher is better quality but costs more performance.";
    ui_min = 4;
    ui_max = 32;
> = 16;

// Gaussian Blur
uniform bool EnableGaussianBlur <
    ui_category = "Gaussian Blur";
    ui_type = "checkbox";
    ui_label = "Enable Gaussian Blur";
> = false;

uniform float GaussianBlurRadius <
    ui_category = "Gaussian Blur";
    ui_type = "slider";
    ui_label = "Radius";
    ui_tooltip = "Controls the spread of the blur.";
    ui_min = 0.0;
    ui_max = 5.0;
    ui_step = 0.01;
> = 1.0;

uniform int GaussianBlurSamples <
    ui_category = "Gaussian Blur";
    ui_type = "slider";
    ui_label = "Samples";
    ui_tooltip = "Number of samples for the Gaussian blur. Higher is better quality but costs more performance.";
    ui_min = 4;
    ui_max = 32;
> = 16;

//Zoom Blur
uniform bool EnableZoomBlur <
    ui_category = "Zoom Blur";
    ui_type = "checkbox";
    ui_label = "Enable Zoom Blur";
> = false;

uniform float ZoomBlurRadius <
    ui_category = "Zoom Blur";
    ui_type = "slider";
    ui_label = "Radius";
    ui_min = 0.0;
    ui_max = 0.1;
    ui_step = 0.001;
> = 0.01;

uniform float2 ZoomBlurCenter <
    ui_category = "Zoom Blur";
    ui_type = "slider";
    ui_label = "Center";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.001;
> = float2(0.5, 0.5);

uniform int ZoomBlurSamples <
    ui_category = "Zoom Blur";
    ui_type = "slider";
    ui_label = "Samples";
    ui_tooltip = "Number of samples. Higher is better quality but costs more performance.";
    ui_min = 2;
    ui_max = 32;
> = 16;

// Fake Motion Blur
uniform bool EnableMotionBlur <
    ui_category = "Fake Motion Blur";
    ui_type = "checkbox";
    ui_label = "Enable Fake Motion Blur";
> = false;

uniform float MotionBlurRadius <
    ui_category = "Fake Motion Blur";
    ui_type = "slider";
    ui_label = "Radius";
    ui_tooltip = "Length of the motion blur trail.";
    ui_min = 0.0;
    ui_max = 0.1;
    ui_step = 0.001;
> = 0.01;

uniform float MotionBlurDirection <
    ui_category = "Fake Motion Blur";
    ui_type = "slider";
    ui_label = "Direction";
    ui_tooltip = "Angle of the motion blur.";
    ui_min = 0.0;
    ui_max = 360.0;
> = 0.0;

uniform int MotionBlurSamples <
    ui_category = "Fake Motion Blur";
    ui_type = "slider";
    ui_label = "Samples";
    ui_tooltip = "Number of samples. Higher is better quality but costs more performance.";
    ui_min = 2;
    ui_max = 32;
> = 16;

//Rotation Blur
uniform bool EnableRotationBlur <
    ui_category = "Rotation Blur";
    ui_type = "checkbox";
    ui_label = "Enable Rotation Blur";
> = false;

uniform float RotationBlurAngle <
    ui_category = "Rotation Blur";
    ui_type = "slider";
    ui_label = "Angle";
    ui_tooltip = "The angle of the blur arc.";
    ui_min = 0.0;
    ui_max = 360.0;
    ui_step = 1.0;
> = 45.0;

uniform float RotationBlurStrength <
    ui_category = "Rotation Blur";
    ui_type = "slider";
    ui_label = "Strength";
    ui_tooltip = "The strength of the rotation blur.";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.001;
> = 0.1;

uniform float2 RotationBlurCenter <
    ui_category = "Rotation Blur";
    ui_type = "slider";
    ui_label = "Center";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_step = 0.001;
> = float2(0.5, 0.5);

uniform int RotationBlurSamples <
    ui_category = "Rotation Blur";
    ui_type = "slider";
    ui_label = "Samples";
    ui_tooltip = "Number of samples. Higher is better quality but costs more performance.";
    ui_min = 2;
    ui_max = 32;
> = 10;

/*----------------.
| ::  Textures :: |
'----------------*/

texture BlurTempTex
{
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
};
sampler BlurTempSampler
{
    Texture = BlurTempTex;
};

/*----------------.
| :: Functions :: |
'----------------*/

float3 ApplyBoxBlur1D(sampler source, float2 uv, float2 direction, float radius, int samples)
{
    float3 color = 0.0;
    float step = radius / (samples / 2.0);

    for (int i = -samples / 2; i <= samples / 2; i++)
    {
        float2 offset = direction * i * ReShade::PixelSize * step;
        color += tex2D(source, uv + offset).rgb;
    }

    return color / (samples + 1);
}

float Gaussian(float x, float sigma)
{
    return exp(-0.5 * (x * x) / (sigma * sigma));
}

float3 ApplyGaussianBlur1D(sampler source, float2 uv, float2 direction, float radius, int samples)
{
    float3 color = 0.0;
    float total_weight = 0.0;
    float sigma = samples / 2.0;

    for (int i = -samples / 2; i <= samples / 2; i++)
    {
        float weight = Gaussian(i, sigma);
        float2 offset = direction * i * ReShade::PixelSize * radius;
        color += tex2D(source, uv + offset).rgb * weight;
        total_weight += weight;
    }

    return color / total_weight;
}

float3 ApplyZoomBlur(float2 uv, float2 center, float radius, int samples)
{
    float3 blurred_color = 0.0;
    float2 dir = uv - center;

    for (int i = 0; i < samples; i++)
    {
        float percent = (float) i / (samples - 1);
        blurred_color += GetColor(uv - dir * percent * radius).rgb;
    }

    return blurred_color / samples;
}

float3 ApplyMotionBlur(float2 uv, float radius, float angle, int samples)
{
    float3 blurred_color = 0.0;
    float rad_angle = radians(angle);
    float2 direction = float2(cos(rad_angle), sin(rad_angle));

    for (int i = 0; i < samples; i++)
    {
        float percent = (float) i / (samples - 1);
        float2 offset = direction * lerp(0.0, -radius, percent);
        blurred_color += GetColor(uv + offset).rgb;
    }
    
    return blurred_color / samples;
}

float3 ApplyRotationBlur(float2 uv, float2 center, float angle, float strength, int samples)
{
    float3 blurred_color = 0.0;
    float2 dir = uv - center;
    float total_angle = radians(angle) * strength;

    for (int i = 0; i < samples; i++)
    {
        float percent = (float) i / (samples - 1);
        float current_angle = lerp(-total_angle / 2.0, total_angle / 2.0, percent);
        
        float s, c;
        sincos(current_angle, s, c);
        
        float2 rotated_dir = float2(
            dir.x * c - dir.y * s,
            dir.x * s + dir.y * c
        );
        
        blurred_color += GetColor(center + rotated_dir).rgb;
    }

    return blurred_color / samples;
}


/*--------------------.
| :: Pixel Shaders :: |
'--------------------*/

float3 PS_BlurPass1(float4 pos : SV_Position, float2 uv : TexCoord) : SV_Target
{
    if (!EnableGaussianBlur && !EnableBoxBlur)
        return GetColor(uv).rgb;
    
    float3 result = 0.0;
    int active_blurs = 0;

    if (EnableGaussianBlur)
    {
        result += ApplyGaussianBlur1D(ReShade::BackBuffer, uv, float2(1.0, 0.0), GaussianBlurRadius, GaussianBlurSamples);
        active_blurs++;
    }
    if (EnableBoxBlur)
    {
        result += ApplyBoxBlur1D(ReShade::BackBuffer, uv, float2(1.0, 0.0), BoxBlurRadius, BoxBlurSamples);
        active_blurs++;
    }

    return (active_blurs > 0) ? result / active_blurs : GetColor(uv).rgb;
}

float4 FinalPass(float4 pos : SV_Position, float2 uv : TexCoord) : SV_Target
{
    float3 original_color = GetColor(uv).rgb;
    float3 final_color = original_color;

    float3 blended_color = 0.0;
    int active_blurs = 0;

    if (EnableGaussianBlur)
    {
        blended_color += ApplyGaussianBlur1D(BlurTempSampler, uv, float2(0.0, 1.0), GaussianBlurRadius, GaussianBlurSamples);
        active_blurs++;
    }
    if (EnableBoxBlur)
    {
        blended_color += ApplyBoxBlur1D(BlurTempSampler, uv, float2(0.0, 1.0), BoxBlurRadius, BoxBlurSamples);
        active_blurs++;
    }

    if (EnableZoomBlur)
    {
        blended_color += ApplyZoomBlur(uv, ZoomBlurCenter, ZoomBlurRadius, ZoomBlurSamples);
        active_blurs++;
    }
    if (EnableMotionBlur)
    {
        blended_color += ApplyMotionBlur(uv, MotionBlurRadius, MotionBlurDirection, MotionBlurSamples);
        active_blurs++;
    }
    if (EnableRotationBlur)
    {
        blended_color += ApplyRotationBlur(uv, RotationBlurCenter, RotationBlurAngle, RotationBlurStrength, RotationBlurSamples);
        active_blurs++;
    }

    if (active_blurs > 0)
    {
        float3 averaged_blur_color = blended_color / active_blurs;
        final_color = ComHeaders::Blending::Blend(BlurBlendMode, original_color, averaged_blur_color, BlurMix);
    }

    return float4(saturate(final_color), 1.0);
}

/*------------------.
| :: Technique ::   |
'------------------*/

technique BlurSuite
{
    pass BlurPassHorizontal
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_BlurPass1;
        RenderTarget = BlurTempTex;
    }
    pass Final
    {
        VertexShader = PostProcessVS;
        PixelShader = FinalPass;
    }
}
