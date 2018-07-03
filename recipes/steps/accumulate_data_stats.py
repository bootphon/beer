
'''Accumulate data statistics: mean, standard deviation and total data points
'''
import numpy as np
import argparse

def accumulate(feature_file):
    '''Compute global mean, std, frame counts and per utterance mean, std
    Argument:
        feature_file(str): feature file(npz)
    Returns:
        global_mean: np array (float)
        global_std: np array (float)
        tot_counts(int): total frames in feature files
        dict_utts: uttid(str) -> [per_utt_mean(np.array(float)), 
                                  per_utt_var(np.array(float))]
    '''

    feats = np.load(feature_file)
    keys = list(feats.keys())
    dim = feats[feats.keys()[0]].shape[1]
    tot_sum = np.zeros(dim)
    tot_square_sum = np.zeros(dim)
    tot_counts = 0
    dict_utt_details = {}
    for k in keys:
        dict_utt_details[k] = []
        nframes_per_utt = len(feats[k])
        per_square_sum = (feats[k] ** 2).sum(axis=0)
        per_utt_mean = feats[k].mean(axis=0)
        per_utt_std = np.sqrt(per_square_sum / nframes_per_utt - per_utt_mean ** 2) 
        tot_sum += feats[k].sum(axis=0)
        tot_square_sum += per_square_sum
        tot_counts += nframes_per_utt
        dict_utt_details[k].append(per_utt_mean)
        dict_utt_details[k].append(per_utt_std)

    global_mean = tot_sum / tot_counts
    global_std = np.sqrt(tot_square_sum / tot_counts - global_mean ** 2)
    return global_mean, global_std, int(tot_counts), dict_utt_details

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('features', type=str, help='Feature file')
    parser.add_argument('stats', type=str, help='Feature statistics')
    args = parser.parse_args()

    feats = args.features
    data_stats = args.stats
    
    global_mean, global_std, tot_counts, _ = accumulate(feats)
    stats = {'global_mean': global_mean, 'global_std': global_std, 'nframes': tot_counts}
    np.savez(data_stats, **stats)

if __name__ == "__main__":
    main()