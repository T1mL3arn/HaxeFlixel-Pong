// src https://www.shadertoy.com/view/lsXGWn

#pragma header

// uniform float blurSize;
// uniform float intensity;
float blurSize = 1.0/256.0;
float intensity = 0.25;

void main()
{
   vec4 color = vec4(0.0);
   vec2 uv = openfl_TextureCoordv.xy;

   //thank you! http://www.gamerendering.com/2008/10/11/gaussian-blur-filter-shader/ for the 
   //blur tutorial
   // blur in x (horizontal)
   // take nine samples, with the distance blurSize between them
   color += texture2D(bitmap, vec2(uv.x - 4.0*blurSize, uv.y)) * 0.05;
   color += texture2D(bitmap, vec2(uv.x - 3.0*blurSize, uv.y)) * 0.09;
   color += texture2D(bitmap, vec2(uv.x - 2.0*blurSize, uv.y)) * 0.12;
   color += texture2D(bitmap, vec2(uv.x - blurSize, uv.y)) * 0.15;
   color += texture2D(bitmap, vec2(uv.x, uv.y)) * 0.16;
   color += texture2D(bitmap, vec2(uv.x + blurSize, uv.y)) * 0.15;
   color += texture2D(bitmap, vec2(uv.x + 2.0*blurSize, uv.y)) * 0.12;
   color += texture2D(bitmap, vec2(uv.x + 3.0*blurSize, uv.y)) * 0.09;
   color += texture2D(bitmap, vec2(uv.x + 4.0*blurSize, uv.y)) * 0.05;
	
	// blur in y (vertical)
   // take nine samples, with the distance blurSize between them
   color += texture2D(bitmap, vec2(uv.x, uv.y - 4.0*blurSize)) * 0.05;
   color += texture2D(bitmap, vec2(uv.x, uv.y - 3.0*blurSize)) * 0.09;
   color += texture2D(bitmap, vec2(uv.x, uv.y - 2.0*blurSize)) * 0.12;
   color += texture2D(bitmap, vec2(uv.x, uv.y - blurSize)) * 0.15;
   color += texture2D(bitmap, vec2(uv.x, uv.y)) * 0.16;
   color += texture2D(bitmap, vec2(uv.x, uv.y + blurSize)) * 0.15;
   color += texture2D(bitmap, vec2(uv.x, uv.y + 2.0*blurSize)) * 0.12;
   color += texture2D(bitmap, vec2(uv.x, uv.y + 3.0*blurSize)) * 0.09;
   color += texture2D(bitmap, vec2(uv.x, uv.y + 4.0*blurSize)) * 0.05;

	// original
	//gl_FragColor = color*intensity + texture2D(bitmap, uv);

	vec4 origColor = texture2D(bitmap, uv);

   // SCREEN blending
	gl_FragColor = 1.0-(1.0-origColor)*(1.0-color*intensity);

   // gl_FragColor = color*intensity + origColor;
}