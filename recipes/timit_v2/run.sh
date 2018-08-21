#!/bin/sh


# Load the configuration.

if [ $# -ne 1 ]; then
    echo "$0 <setup.sh>"
    exit 1
fi
setup=$(pwd)/$1
. $setup
stage=0

if [ $stage -le 0 ]; then
    echo ======================================================================
    echo "                         Data Preparation                           "
    echo ======================================================================
    local/timit_data_prep.sh "$timit" "$langdir" "$confdir" || exit 1
fi

if [ $stage -le 1 ]; then
    for s in train test dev; do
        echo "Preparing for $datadir/$s"
        mkdir -p $datadir/$s
        cp $datadir/local/data/${s}_wav.scp $datadir/$s/wav.scp
        cp $datadir/local/data/$s.uttids $datadir/$s/uttids
        cp $datadir/local/data/$s.text $datadir/$s/trans
        python utils/prepare_trans.py \
            $datadir/$s/trans $langdir/phones.txt $datadir/$s
    done
fi

if [ $stage -le 2 ]; then
    echo ======================================================================
    echo "                         Features Extraction                        "
    echo ======================================================================
    for s in train test dev; do
        echo "Extracting features for: $s"
        steps/extract_features.sh $setup $datadir/$s || exit 1
    done
fi

if [ $stage -le 3 ]; then
    echo ======================================================================
    echo "                         HMM-GMM Training and decoding              "
    echo ======================================================================
    steps/train_hmm.sh $setup
    steps/decode_hmm.sh $setup

fi
