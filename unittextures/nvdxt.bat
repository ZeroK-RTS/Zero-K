#NVDXT
#common nvdxt commandline flags for used model textures in CA

#note: instead of -all (and -outdir %dir), you can just use -file %filename, too


### s3o texture 1
#format: normally dxt5 (for hard-edged textures prefer dxt3)
#size: 128x128 - 512x512 (rarely 1024x1024)

nvdxt -all -clampScale 128, 128 -dither -quality_highest -dxt5 -sharpenMethod SharpenSoft
nvdxt -all -clampScale 256, 256 -dither -quality_highest -dxt5 -sharpenMethod SharpenSoft
nvdxt -all -clampScale 512, 512 -dither -quality_highest -dxt5 -sharpenMethod SharpenSoft



### s3o texture 2
#format: dxt1c (except you are using the 1bit transparency like corvp does, then use either dxt5 or dxt3)
#size: fourth of tex1, e.g. tex1 is 512x512, then tex2 should be 256x256

nvdxt -all -clampScale 256, 256 -dither -quality_highest -dxt1c -sharpenMethod SharpenSoft
nvdxt -all -clampScale 128, 128 -dither -quality_highest -dxt1c -sharpenMethod SharpenSoft



### normalmaps
#format: dxt1c
#size: same as tex1 (!)

#note: you may want to experiment with the -n & the -scale tag
#  -n: determines the kernel size (=radius) for the normal generation, possible values are:
#      -n4,-n3x3,-n5x5,-n7x7,-n9x9
#      something between 3x3 (hardedges) and 7x7 (smooth) gives good results
#  -scale: the generated heightmap is multiplied with this given value,
#      you can use it too emphasize the normalmap
#      values between 1.0 (weak) and 7.0 (strong) gives good results

### creating a normalmap from a diffusetex (e.g. s3o tex1)
nvdxt -all -clampScale 512, 512 -dxt1c -quality_highest -rgb -Sinc -n5x5 -scale 2.0 -sharpenMethod Smoothen

### renormalizing an existing one
nvdxt -all -clampScale 512, 512 -dxt1c -quality_highest -Sinc -norm -sharpenMethod Smoothen
