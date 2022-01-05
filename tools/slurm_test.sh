#!/bin/bash
#SBATCH --time=71:59:59
#SBATCH --account=gard
#SBATCH --qos=premium_memory
#SBATCH --cpus-per-task=10
#SBATCH --partition=large_gpu
#SBATCH --nodes=1-1
#SBATCH --ntasks=1
#SBATCH --gres=gpu:4
#SBATCH --mem-per-gpu=20G

CONFIG=$1
GPUS=$2
CHECKPOINT=$3
PORT=${PORT:-29500}
TMP_CONFIG=$TMPDIR"/tmp_config.py"

echo $HOSTNAME" gpus allocated: "$CUDA_VISIBLE_DEVICES
echo "using config: "$CONFIG
echo "gpus used: "$GPUS
echo "chkpt used: "$CHECKPOINT
echo "port used: "$PORT

cp /nas/vista-ssd02/users/jmathai/bdd100k_qdtrack_data.tar $TMPDIR
tar -xf $TMPDIR/bdd100k_qdtrack_data.tar --directory $TMPDIR

eval "$(command conda 'shell.bash' 'hook' 2> /dev/null)"
conda activate qdtrack

PYTHONPATH="$(dirname $0)/..":$PYTHONPATH \
python -m torch.distributed.launch --nproc_per_node=$GPUS --master_port=$PORT \
    $(dirname "$0")/test.py $CONFIG $CHECKPOINT --launcher pytorch --eval track bbox \
    --out $CHECKPOINT".pkl" --data-root $TMPDIR/data/bdd
