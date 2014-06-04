% Compile mex functions
mex -O -outdir features features/features.cc
mex -O -outdir features features/resize.cc
mex -O -outdir features features/reduce.cc
mex -O -outdir features features/fconv.cc
mex -O -outdir features features/fconvsse.cc
mex -O -outdir detection detection/fast_bounded_dt.cc
