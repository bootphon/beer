#!/bin/sh

gpu=  # Empty variable means we don't use the GPU.
lograte=100
pt_epochs=5
epochs=10
lrate=.1
lrate_nnet=1e-3
nsamples=5
train_cmd=utils/train-vae-discrete-latent-model.py

usage() {
echo "Usage: $0 [options] <sge-options> <init-model> <dbstats> <archives> <outdir>"
}

help() {
echo "\
Train a Variational Auto-Encoder model with discrete latent
variable prior (i.e. GMM or similar).

Note:
  The training has two stages, first the model is pre-trained
  with the KL divergence term weighted to zero so the
  encoder/decoder are decoupled from the latent prior. Then, the
  second stage of the training is the standard optimization of
  the ELBO function (KL divergence weight is set to 1).
"
usage
echo "
Options:
  -h --help        show this message
  --use-gpu        use gpu for the training
  --unsupervised   unsupervised training (ignore the labels if
                   any)
  --lograte        log message rate
  --pt-epochs      number of epochs for the pre-training
  --epochs         number of epochs for the training
  --lrate          learning rate for the latent model
  --lrate-nnet     learning for the encoder/decoder networks
  --nsamples       number of samples for the re-parameterization
                   trick

Example:
  \$ $0 \\
            --pt-epochs=1 \\
            --epochs=10 \\
            --lrate=.1 \\
            --lrate-nnet=1e-3 \\
            --nsamples=5 \\
            -- \\
            \"-l mem_free=1G,ram_free=1G\" \\
             /path/to/init.mdl \\
             /path/to/dbstats.npz \\
             /path/to/archives/ expdir

Note the double hyphens \"--\" to avoid problem when parsing
the SGE option \"-l ...\".

The final model is written in \"<outdir>/final.mdl\".
"
}

# Parsing optional arguments.
while [ $# -ge 0 ]; do
    param=$(echo $1 | awk -F= '{print $1}')
    optname=$(echo ${param} | sed 's/--//g' | sed 's/-/_/g')
    value=`echo $1 | awk -F= '{print $2}'`
    case $param in
        -h | --help)
            help
            exit
            ;;
        --use-gpu)
            gpu="--use-gpu"
            shift
            ;;
        --unsupervised)
            train_cmd=utils/train-vae-model.py
            shift
            ;;
        --lograte | \
        --pt-epochs | \
        --epochs | \
        --lrate | \
        --lrate-nnet | \
        --nsamples)
            eval ${optname}=${value}
            shift
            ;;
        --)
            shift
            break
            ;;
        -*)
            usage
            exit 1
            ;;
        *)
            break
    esac
done

# Parsing mandatory arguments.
if [ $# -ne 5 ]; then
    usage
    exit 1
fi

echo lrate: ${lrate}
echo lrate_nnet: ${lrate_nnet}

sge_options=$1
init_model=$2
dbstats=$3
archives=$4
root=$5

# Build the output directory followin the parameters.
outdir="${root}/ptepochs${pt_epochs}_epochs${epochs}_lrate${lrate}_lratennet${lrate_nnet}_nsamples${nsamples}"
mkdir -p ${outdir}/pretraining ${outdir}/training

################
# Pre-training #
################

# Build the output directory followin the parameters.
pretraining_options="\
--epochs ${pt_epochs}  \
${gpu}  \
--lrate ${lrate}  \
--lrate-nnet ${lrate_nnet} \
--logging-rate ${lograte}  \
--dir-tmp-models ${outdir}/pretraining \
--nsamples ${nsamples} \
--kl-weight 0. \
"

if [ ! -f "${outdir}/pretraining/.done" ]; then
    echo "Pre-training..."
    # Command to submit to the SGE.
    cmd="python "${train_cmd}" \
        ${pretraining_options} \
        ${dbstats} \
        ${archives} \
        ${init_model} \
        ${outdir}/pretraining/final.mdl"

    # Clear the log file.
    rm -f ${outdir}/pretraining/sge.log

    # Submit the command to the SGE.
    qsub \
        ${sge_options} \
        -wd $(pwd)\
        -j y \
        -sync y \
        -o ${outdir}/pretraining/sge.log \
        utils/job.qsub \
        "${cmd}" || exit 1

    date > "${outdir}/pretraining/.done"
else
    echo "Model already pre-trained. Skipping."
fi


############
# Training #
############

training_options="\
--epochs ${epochs}  \
${gpu}  \
--lrate ${lrate}  \
--lrate-nnet ${lrate_nnet} \
--logging-rate ${lograte}  \
--dir-tmp-models ${outdir}/training \
--nsamples ${nsamples} \
--kl-weight 1. \
"

if [ ! -f "${outdir}/training/.done" ]; then
    echo "Training..."
    # Command to submit to the SGE.
    cmd="python "${train_cmd}" \
        ${training_options} \
        ${dbstats} \
        ${archives} \
        ${outdir}/pretraining/final.mdl \
        ${outdir}/training/final.mdl"

    # Clear the log file.
    rm -f ${outdir}/training/sge.log

    # Submit the command to the SGE.
    qsub \
        ${sge_options}\
        -wd $(pwd)\
        -j y \
        -sync y \
        -o ${outdir}/training/sge.log \
        utils/job.qsub \
        "${cmd}" || exit 1

    cp "${outdir}/training/final.mdl" "${root}"

    date > "${outdir}/training/.done"
else
    echo "Model already trained. Skipping."
fi

