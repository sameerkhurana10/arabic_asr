export KALDI_ROOT=/data/sls/qcri-scratch/sameer/finetune_asr/kaldi
[ -f $KALDI_ROOT/tools/env.sh ] && . $KALDI_ROOT/tools/env.sh
export PATH=$PWD/utils/:$KALDI_ROOT/tools/openfst/bin:$PWD:$PATH
[ ! -f $KALDI_ROOT/tools/config/common_path.sh ] && echo >&2 "The standard file $KALDI_ROOT/tools/config/common_path.sh is not present -> Exit!" && exit 1
. $KALDI_ROOT/tools/config/common_path.sh
# Kaldi is compiled against the below cuda libs
export CUDA_HOME=/data/sls/temp/sameerk/tools/cuda-8.0
export LD_LIBRARY_PATH=/data/sls/temp/sameerk/tools/cuda-8.0/lib64
export CUDA_CACHE_PATH=/data/sls/qcri/asr/sameer_v1/.nv/ComputeCache
export LC_ALL=C
