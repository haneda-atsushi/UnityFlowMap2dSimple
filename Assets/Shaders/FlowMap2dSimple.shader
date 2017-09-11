// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/FlowMap2dSimple"
{
    Properties
    {
	    _MainTex("Base (RGB)", 2D) = "white" {}
		_FlowMap("FlowMap(RG)", 2D) = "white" {}
        _PhaseMap( "PhaseMap(R)", 2D ) = "black" {}
        _Speed( "Speed", Range( 0.0, 1.0 ) ) = 0.4
        _FlowIntensity( "FlowIntensity", Range( 0.0, 1.0 ) ) = 0.25
        _FlowSignX( "FlowSignX", Range( -1.0, 1.0 ) ) = 1.0
        _FlowSignY( "FlowSignY", Range( -1.0, 1.0 ) ) = -1.0
        // _FlowOffset( "FlowOffset", Range( -1.0, 1.0 ) ) = -0.5
    }

    SubShader
    {
        Tags{ "RenderType" = "Opaque" "Queue" = "Geometry" "ForceNoShadowCasting" = "True" }
        LOD 200

        Pass
        {
            CGPROGRAM

#pragma vertex   my_vert
#pragma fragment my_frag

#pragma target 3.0

            sampler2D _MainTex;
            sampler2D _FlowMap;
            sampler2D _PhaseMap;

            float     _Speed;
            float     _FlowIntensity;
            float     _FlowSignX;
            float     _FlowSignY;
            // float     _FlowOffset;

            struct VertexInput
            {
                float4 pos      : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct VertexOutput
            {
                float4 pos      : SV_POSITION;
                float2 texcoord : TEXCOORD0;
            };

            VertexOutput my_vert ( VertexInput vertex_input )
            {
                VertexOutput vertex_output;

                vertex_output.pos      = UnityObjectToClipPos (  vertex_input.pos );
                vertex_output.texcoord = vertex_input.texcoord;

                return vertex_output;
            }

            float4 my_frag ( VertexOutput vertex_output ) : COLOR
            {
                float2 uv           = vertex_output.texcoord;

                float time          = _Time[ 1 ];
                float offset        = tex2D( _PhaseMap, uv ).r;

                float flow_scale0   = frac( _Speed * time + offset        );
                float flow_scale1   = frac( _Speed * time + offset + 0.5f );

                float2 flow_raw_dir = tex2D( _FlowMap, uv ).rg;
                flow_raw_dir        = 2.0 * ( flow_raw_dir.xy - float2( 0.5, 0.5 ) );
                flow_raw_dir        *= float2( _FlowSignX, _FlowSignY );

                float2 flow_dir     = flow_raw_dir * _FlowIntensity;
                // float2 flow_offset  = flow_raw_dir * _FlowOffset;
                float2 flow_uv0     = uv + flow_dir * flow_scale0;
                float2 flow_uv1     = uv + flow_dir * flow_scale1;

                //float2 flow_uv0     = uv + flow_dir * flow_scale0 + flow_offset;
                //float2 flow_uv1     = uv + flow_dir * flow_scale1 + flow_offset;

                float alpha         = abs( 2.0f * ( flow_scale0 - 0.5 ) );

                float4 base_color0  = tex2D( _MainTex, flow_uv0 );
                float4 base_color1  = tex2D( _MainTex, flow_uv1 );
                float4 base_color   = lerp( base_color0, base_color1, alpha );

                return base_color;
            }

            ENDCG
        }
    }

    Fallback "Mobile/VertexLit"
}
