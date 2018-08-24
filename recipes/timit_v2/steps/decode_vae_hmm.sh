#!/bin/bash

if [ $# -ne 4 ];then
    echo "$0 <setup.sh> <model-dir> <date-test-dir> <decode-dir> "
    exit 1
fi

setup=$1
mdl=$2
data_test_dir=$3
decode_dir=$4
mdldir=$(dirname $mdl)
stage=0

[ -f $setup ] && . $setup
mkdir -p $decode_dir/log

pdf_mapping=$mdldir/pdf_mapping.txt
for f in $mdl $pdf_mapping ; do
    [ ! -f $f ] && echo "No such file: $f" && exit 1;
done

if [ ! -f $decode_dir/decode_phone_ids.npz ];then
    echo "Decoding"
    python utils/vae-hmm-decode.py $mdl $data_test_dir/feats.npz | \
        python utils/pdf2unit.py --phone-level $pdf_mapping  \
        > $decode_dir/decode_results.txt
fi

if [ ! -f $decode_dir/decode_result.txt ];then
    python utils/score.py \
        --remove=$remove_sym \
        --duplicate=$duplicate \
        --phone_map=$phone_48_to_39_map \
        $data_test_dir/trans \
        $decode_dir/decode_results.txt > $decode_dir/log/score.log 2>&1 || exit 1
fi
