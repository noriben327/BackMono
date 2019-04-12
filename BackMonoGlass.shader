Shader "Unlit/BackMonoGlass"
{
    Properties
    {
        _Reflection("Reflection", Range(0, 1)) = 0.2
    }
    SubShader
    {
        Tags {
            "RenderType"="Transparent"
            "Queue" = "Transparent"
            }
        LOD 100
        GrabPass {"_GrabPassTexture"}
        Cull off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float4 uvGrab : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 uvGrab : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 screenPos : TEXCOORD1;
                float3 pos2 : TEXCOORD2;
                float3 normal : TEXCOORD3;
            };

            sampler2D _GrabPassTexture;
            
            fixed _Reflection;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos( v.vertex );
                o.uvGrab = ComputeGrabScreenPos(o.vertex);
                o.pos2 = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.normal = UnityObjectToWorldNormal(v.normal);
                return o;
            }
            
            fixed4 frag (v2f i, fixed facing : VFACE) : SV_Target
            {
                //環境マップ
                i.normal = normalize(i.normal);
                half3 viewDir = normalize(_WorldSpaceCameraPos - i.pos2);
                half3 reflDir = reflect(-viewDir, i.normal);
                // キューブマップと反射方向のベクトルから反射先の色を取得する
                half4 refColor = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, reflDir);
                
                //GrabPassのテクスチャ
                float4 grabTex = tex2Dproj(_GrabPassTexture, i.uvGrab) + (refColor * _Reflection); 
                float4 col = float4(0, 0, 0, 1);   

                //裏面だけモノクロ
                if (facing > 0){
                    col = grabTex;
                }
                else {
                    //モノクロ変換
				    const float3 monochromeScale = float3(0.298912, 0.586611, 0.114478);
				    float grayColor = dot(grabTex.rgb, monochromeScale);

                    col = float4(grayColor, grayColor, grayColor, 1);
                }
                
                return col;
            }
            ENDCG
        }
    }
}
