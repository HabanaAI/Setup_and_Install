#!/bin/bash

NUM_NODES="${NUM_NODES:-1}";
HOME_DIR="${HOME_DIR:-/tmp/ighs/intel_gaudi_health_screen}";
WORK_DIR="${WORK_DIR:-/tmp/ighs/intel_gaudi_health_screen/build/hccl_demo}";

NGPU_PER_NODE=8;
N_CARDS=$((NUM_NODES*NGPU_PER_NODE));

cd ${WORK_DIR};
CMD="python ${WORK_DIR}/run_hccl_demo.py \
--test all_reduce \
--loop 1000 \
--size 32m \
-mpi ";

mkdir -p $HOME_DIR/$LOG_DIR/L2/$ROUND/;
cat /dev/null > $HOME_DIR/$LOG_DIR/L2/$ROUND/$JOB_ID.log;
touch $HOME_DIR/$LOG_DIR/L2/$ROUND/$JOB_ID.log;
echo "Target Nodes: $TARGET_NODES" >> $HOME_DIR/$LOG_DIR/L2/$ROUND/$JOB_ID.log;

$CMD \
-np ${N_CARDS} \
--allow-run-as-root \
--bind-to core \
--map-by ppr:4:socket:PE=6 \
--rank-by core --report-bindings \
--tag-output \
--merge-stderr-to-stdout --prefix $MPI_ROOT \
-H ${TARGET_NODES//,/:48,}:48 \
--mca btl_tcp_if_include $TCP_INTERFACE \
-x MASTER_ADDR \
-x PYTHONPATH="/usr/lib/habanalabs/:$PYTHONPATH" \
-x ENABLE_CONSOLE="true" -x LOG_LEVEL_ALL=4 \
2>&1 | ts '[%Y-%m-%d %H:%M:%S]' | tee -a $HOME_DIR/$LOG_DIR/L2/$ROUND/$JOB_ID.log;

cd ${HOME_DIR};
python $HOME_DIR/screen.py --ighs-check hccl-demo --logs-dir $LOG_DIR --job-id $JOB_ID --target-nodes $TARGET_NODES --node-name $MY_NODE_NAME;

chmod 777 -R $HOME_DIR/$LOG_DIR
