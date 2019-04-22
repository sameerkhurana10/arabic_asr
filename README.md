**Install kaldi**

https://github.com/kaldi-asr/kaldi

**Setup**:

After installing kaldi, change the `KALDI_ROOT` in the `path.sh` to point to your local kaldi

Also, run the following commands

`ln -sf <your_kaldi_folder>/egs/wsj/s5/steps .`

`ln -sf <your_kaldi_folder>/egs/wsj/s5/utils .`

**Data prep**:

Create a folder, say, `data/dsat`. Create three files in the folder as follows:

`wav.scp` : Each line is of the form `id audio_file_path`

`utt2spk`: Each line is of the form `id id`

`spk2utt`: same as spk2utt. To create this file just run `cp utt2spk spk2utt`

For example, see `data/test_data`, a folder that I created

**Download Pre-packaged Stuff**

Download the folder from google drive `https://drive.google.com/open?id=1w6PKskKrFNMfumkLDqvAul5fPjHDXHO5`

inside this repo, run `tar -xzvf exp.tar.gz`, this will create a folder `exp`.

The `exp` folder contains all the necessary items used to run decoding and transcribe speech. Also, it contains the pre-trained Arabic ASR model

**Extract features**:

1. MFCC

Extract MFCC features using the command below:

```
Usage: steps/make_mfcc.sh [options] <data-dir> [<log-dir> [<mfcc-dir>] ]
e.g.: steps/make_mfcc.sh data/train exp/make_mfcc/train mfcc
Note: <log-dir> defaults to <data-dir>/log, and <mfccdir> defaults to <data-dir>/data
Options: 
  --mfcc-config <config-file>                      # config passed to compute-mfcc-feats 
  --nj <nj>                                        # number of parallel jobs
  --cmd (utils/run.pl|utils/queue.pl <queue opts>) # how to run jobs.
  --write-utt2num-frames <true|false>     # If true, write utt2num_frames file

```

Concretely, I ran:

`steps/make_mfcc.sh --cmd "run.pl" --nj 1 --mfcc-config conf/mfcc_hires.conf data/test_data exp/make_hires/test_data mfcc`

Expected output on Command Line:

```
utils/validate_data_dir.sh: Successfully validated data-directory data/test_data
steps/make_mfcc.sh: [info]: no segments file exists: assuming wav.scp indexed by utterance.
Succeeded creating MFCC features for test_data
```

2. Ivectors

Extract the i-vectors using the command below:

```
steps/online/nnet2/extract_ivectors_online.sh 
Usage: steps/online/nnet2/extract_ivectors_online.sh [options] <data> <extractor-dir> <ivector-dir>
 e.g.: steps/online/nnet2/extract_ivectors_online.sh data/train exp/nnet2_online/extractor exp/nnet2_online/ivectors_train
main options (for others, see top of script file)
  --config <config-file>                           # config containing options
  --cmd (utils/run.pl|utils/queue.pl <queue opts>) # how to run jobs.
  --nj <n|10>                                      # Number of jobs
  --stage <stage|0>                                # To control partial reruns
  --num-gselect <n|5>                              # Number of Gaussians to select using
                                                   # diagonal model.
  --min-post <float;default=0.025>                 # Pruning threshold for posteriors
  --ivector-period <int;default=10>                # How often to extract an iVector (frames)

```

Concretely, I ran:

`steps/online/nnet2/extract_ivectors_online.sh --cmd “run.pl" --nj 1 data/test_data exp/nnet3/extractor exp/nnet3/ivectors_test_data`

Expected command line output:

```
steps/online/nnet2/extract_ivectors_online.sh: extracting iVectors
steps/online/nnet2/extract_ivectors_online.sh: combining iVectors across jobs
steps/online/nnet2/extract_ivectors_online.sh: done extracting (online) iVectors to exp/nnet3/ivectors_test_data using the extractor in exp/nnet3/extractor
```

Decode:

See the command line options:

Now, we run decoding:

```
steps/nnet3/decode.sh [options] <graph-dir> <data-dir> <decode-dir>
e.g.:   steps/nnet3/decode.sh --nj 8 \
--online-ivector-dir exp/nnet2_online/ivectors_test_eval92 \
    exp/tri4b/graph_bg data/test_eval92_hires /decode_bg_eval92
main options (for others, see top of script file)
  --config <config-file>                   # config containing options
  --nj <nj>                                # number of parallel jobs
  --cmd <cmd>                              # Command to run in parallel with
  --beam <beam>                            # Decoding beam; default 15.0
  --iter <iter>                            # Iteration of model to decode; default is final.
  --scoring-opts <string>                  # options to local/score.sh
  --num-threads <n>                        # number of threads to use, default 1.
  --use-gpu <true|false>                   # default: false.  If true, we recommend
                                           # to use large --num-threads as the graph
                                           # search becomes the limiting factor.
```

Concretely,I ran the following:

`steps/nnet3/decode.sh --nj 1 --cmd run.pl --acwt 1.0 --post-decode-acwt 10.0 --online-ivector-dir exp/nnet3/ivectors_test_data exp/mer80/chain/tdnn_7b/graph_tg data/test_data exp/mer80/chain/tdnn_7b/decode_test_data`

Expected command line output:

```
steps/nnet2/check_ivectors_compatible.sh: WARNING: One of the directories do not contain iVector ID.
steps/nnet2/check_ivectors_compatible.sh: WARNING: That means it's you who's reponsible for keeping 
steps/nnet2/check_ivectors_compatible.sh: WARNING: the directories compatible
steps/nnet3/decode.sh: feature type is raw
```

Transcribe:  

`lattice-scale --inv-acoustic-scale=8.0 "ark:gunzip -c exp/mer80/chain/tdnn_7b/decode_test_data/lat.*.gz|" ark:- | lattice-add-penalty --word-ins-penalty=0.0 ark:- ark:- | lattice-prune --beam=8 ark:- ark:- | lattice-mbr-decode  --word-symbol-table=exp/mer80/chain/tdnn_7b/graph_tg/words.txt ark:- ark,t:- | utils/int2sym.pl -f 2- exp/mer80/chain/tdnn_7b/graph_tg/words.txt > transcript.txt`


You should see transcribed speech output in the transcripts.txt
