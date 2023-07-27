#!/usr/bin/env bash

source activate visdialch

# Common paths
export TRAINVAL_DIR=${PWD}
export CURRENT_DIR="$(dirname "$TRAINVAL_DIR")"
export PARENT_DIR="$(dirname "$CURRENT_DIR")"
cd $PARENT_DIR
export CODE_DIR=$PARENT_DIR
export CONFIG_DIR=$CODE_DIR/configs
export PROJECT_DIR="$(dirname "$PARENT_DIR")"

## SA: todo if config also from
export CONFIG_YML=$CONFIG_DIR/trainval/hist_guided_qmcan.yml

export DATA_DIR=$PROJECT_DIR/data
export MODEL_DIR=$PROJECT_DIR/models/hwu_new_models
read -p "Enter the GPU id (as 0/1/2):  " GPU_ID
read -p "Enter the model name:  " MODEL_NAME
export MODEL_NAME=${MODEL_NAME:-hist_guided_qmcan_trainval}


export SAVE_MODEL_DIR=$MODEL_DIR/$MODEL_NAME
mkdir -p $SAVE_MODEL_DIR
echo "Model saved in: " $SAVE_MODEL_DIR

GPU_ID=${GPU_ID:-"0 1 2 3"}
echo "Running on gpus : " $GPU_ID


read -p "Is train: (1 - Yes, 0 - no): " IS_TRAIN
IS_TRAIN=${IS_TRAIN:-0}


if [ $IS_TRAIN == 1 ]; then
echo "Training"
CURRENT_DATE=$(date)
CURRENT_TIME=$(date +"%T")
echo "Current time : $CURRENT_DATE"

export TRAIN_LOG_FILE=$SAVE_MODEL_DIR/train_logs_${MODEL_NAME}.txt


read -p "Is finetune only: (1 - Yes, 0 - no): " IS_FINETUNE
IS_FINETUNE=${IS_FINETUNE:-1}

if [ $IS_FINETUNE == 1 ]; then
export PHASE="finetuning"
else
export PHASE="both"
fi

## SA: todo checkpointing for all
read -p "Enter the checkpoint save finetune number: " CHECKPOINT_FINETUNE_NUM
CHECKPOINT_FINETUNE_NUM=${CHECKPOINT_FINETUNE_NUM:-best}
export CHECKPOINT_FINETUNE_PATH=$SAVE_MODEL_DIR/checkpoint_${CHECKPOINT_FINETUNE_NUM}.pth




echo "Training on phase: " $PHASE
python train.py \
--train-json $DATA_DIR/visdial_1.0_train.json \
--val-json $DATA_DIR/visdial_1.0_val.json \
--val-dense-json $DATA_DIR/visdial_1.0_val_dense_annotations.json \
--train-dense-json $DATA_DIR/visdial_1.0_train_dense_annotations.json \
--save-dirpath $SAVE_MODEL_DIR \
--config-yml $CONFIG_YML \
--validate \
--load_finetune_pthpath $CHECKPOINT_FINETUNE_PATH \
--phase $PHASE \
--data_dir $DATA_DIR \
--gpu-ids $GPU_ID >> $TRAIN_LOG_FILE # provide more ids for multi-GPU execution other args...

fi

read -p "Enter the test checkpoint number: " CHECKPOINT_TEST_NUM
CHECKPOINT_TEST_NUM=${CHECKPOINT_TEST_NUM:-8}
export CHECKPOINT_TEST_PATH=$SAVE_MODEL_DIR/checkpoint_${CHECKPOINT_TEST_NUM}.pth

read -p "Enter split type as (val or test): " SPLIT
SPLIT=${SPLIT:-"test"}


export RANKS_PATH=$SAVE_MODEL_DIR/ranks_${SPLIT}_${CHECKPOINT_TEST_NUM}.json
export LOG_PATH=$SAVE_MODEL_DIR/evaluate_${SPLIT}_${CHECKPOINT_TEST_NUM}.log

CURRENT_DATE=$(date)
CURRENT_TIME=$(date +"%T")
echo "Current time : $CURRENT_TIME $CURRENT_DATE"

python evaluate.py \
--val-json $DATA_DIR/visdial_1.0_val.json \
--val-dense-json $DATA_DIR/visdial_1.0_val_dense_annotations.json \
--test-json $DATA_DIR/visdial_1.0_test.json \
--config-yml $CONFIG_YML \
--load-pthpath $CHECKPOINT_TEST_PATH \
--split $SPLIT \
--save-ranks-path $RANKS_PATH \
--save-dirpath $SAVE_MODEL_DIR \
--data_dir $DATA_DIR \
--gpu-ids $GPU_ID >> $LOG_PATH

echo "Model saved in: " $SAVE_MODEL_DIR
