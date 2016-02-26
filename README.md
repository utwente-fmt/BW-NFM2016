Bandwidth and Wavefront Reduction for Static Variable Ordering in Symbolic Reachability Analysis
================

Instructions for installing LTSmin and replicating the experiments reported in our NFM 2016 submission.

__Warning__: this is a large repository to check out. It contains ~2GB of raw uncompressed data from our benchmarks.
Furthermore, the directory `spec` contains all PNML, DVE, Promela, mCRL2 and B models, also accounting for lots of data.

This readme first instructs how to replicate experiments, then it shows how to perform the data analysis on our benchmarks. The third section in this readme contains instructions for converting dependency matrices into scatter plots, to make them human readable.

1. Reproducing experiments
-
Prerequisites
--
The requirements for reproducing our experiments are the following.
- Linux OS: we tested on Ubuntu 14.02 LTS, other Linux versions and OS X should work as well.
- LTSmin: the model checker
- Memtime: for measuring memory and time

Installing LTSmin
--
LTSmin must be compiled manually.
Manual installation instructions can be found at http://fmt.cs.utwente.nl/tools/ltsmin. Additionally, for the NFM 2016 submission, LTSmin requires two extra dependencies; `Boost` and `ViennaCL`.
Instead of using the git repository described on the webpage, use the `BW-NFM2016` tag at https://github.com/Meijuh/ltsmin/releases/tag/BW-NFM2016.
Additionally, depending on the experiments you want to run, some language front-ends require specific dependencies:
 - `mCRL2` requires mCRL2: http://www.mcrl2.org/release/user_manual/index.html, we used the 201409.1 release.
 - `DVE` requires our patched Divine compiler: https://github.com/utwente-fmt/divine2/releases.
 - `PNML` requires `libxml2`: http://www.xmlsoft.org/
 - `Promela` requires a Java JDK.

### Installing ProB
If you want to run experiments with B, you additionally require `ProB`: http://nightly.cobra.cs.uni-duesseldorf.de/ltsmin. Extract the `.tar.gz` to `<prefix>`. Make sure `<prefix>/probcli` is on your `PATH` and `<prefix>/lib` is on your `LD_LIBRARY_PATH` (or `DYLD_LIBRARY_PATH` on OSX).

Memtime
---
We use memtime for measuring time and memory usage.
The manual installation instructions are the regular commands for autotools:
 - `git clone http://fmt.ewi.utwente.nl/gitweb/?p=memtime.git`
 - `cd memtime`
 - `autoreconf -i`
 - `./configure`
 - `make`
 - `make install`

Running experiments
--

### Performing reorderings

To run an example experiment, pick a Petri net from the `spec/PNML` folder, say `Vasy2003.pnml`.
To perform reordering with the bipartite graph and Sloan run `pnml2lts-sym Vasy2003.pnml -rsc,bg,bs,mm --regroup-exit --graph-metrics`. The output should be similar to the file: https://github.com/utwente-fmt/BW-NFM2016/blob/master/data/job-1483060.log. You can compare the results with no reordering done. To do so, run `pnml2lts-sym Vasy2003.pnml -rsc,bn,mm --regroup-exit --graph-metrics`. The output should be similar to https://github.com/utwente-fmt/BW-NFM2016/blob/master/data/job-1483054.log.

The commandline for running any reordering is as follows `<language>2lts-sym <model> -r<seq> --regroup-exit --graph-metrics [--noack=<1|2>]`, where
 - `<language>` is any of `prob`|`pnml`|`lps`|`prom`|`dve`, for running `B`, `PNML`, `mCRL2`, `Promela` and `DVE` experiments respectively.
 - `<model>` is any file in `spec/`<`B`|`PNML`|`mCRL2`|`Promela`|`DVE`>, make sure `<language>` and `<model>` match, i.e. run only `pnml2lts-sym`for `PNML` models or `prob2lts-sym` for `B` models.
 - `<seq>` is a sequence of transformations to the dependency matrix. A sequence is of the form `(<trans>,)+`, and `<trans>` can be:
     - **sc** for **s**electing the **c**ombined dependencies, this transformation must always be given first.
     - **bg** for using the **b**ipartite **g**raph
     - **tg** for using the **t**otal **g**raph
     - **bcm** for applying **B**oost's **C**uthill **M**cKee algorithm
     - **bk** for applying **B**oost's **K**ing algorithm
     - **bs** for applying **B**oost's **S**loan algorithm
     - **vcm** for applying **V**iennaCL's **C**uthill **M**cKee algorithm
     - **vacm** for applying **V**iennaCL's **a**dvanced **C**uthill **M**cKee algorithm
     - **vgps** for applying **V**iennaCL's **G**ibbs **P**oole **S**tockmeyer algorithm
     - **mm** for printing the current **m**atrix **m**etrics, such as *event span* and *weighted event span*
     - **bn** for creating a graph in **B**oost but applying **n**o algorithm
     - **vn** for creating a graph in **V**iennaCL but applying **n**o algorithm
     - **f** for applying the **F**ORCE algorithm
 - `--regroup-exit` makes sure no reachability analysis is done after reordering
 - `--graph-metrics` prints the graph metrics in ViennaCL and Boost, such as *bandwidth*, *profile* and *wavefront*.
 - `[--noack=<1|2>]` runs Noack's algorithm (either variant 1 or 2). But this can only be done on Petri nets, i.e. when using the binary `pnml2lts-sym`.

#### Running `mCRL2` models
Running `mCRL2` models requires special attention. The `mCRL2` models require linearization first. When `mCRL2` is installed run `mcrl22lps -nDf <file>.mcrl2 <file>.lps`. Next run `lpsrewr <file>.lps <file.lps>`. Next run `lpssuminst <file>.lps <file>.lps`. If the latter `lpssuminst` does not finish in time, skip the `lpssuminst` command. We did this as well in our experiments. For our used time limit and memory limit see https://github.com/utwente-fmt/BW-NFM2016/blob/master/mcrl22all.

### Performing symbolic reachability analysis
To perform symbolic reachability analysis with `LTSmin`'s saturation algorithm you can run the following commandline: `<language>2lts-sym <model> -r<spec> --saturation=sat-like --order=chain --next-union --vset=lddmc --lddmc-cachesize=24 --lddmc-maxcachesize=24 --lddmc-tablesize=24 --lddmc-maxtablesize=24 --lace-workers=1 --peak-nodes`, where:
 - `<language>`, `<model>` and `<spec>` are as described earlier. 
 - `--saturation=sat-like --order=chain --next-union` configures the reachability algorithm.
 - `--vset=lddmc --lddmc-cachesize=24 --lddmc-maxcachesize=24 --lddmc-tablesize=24 --lddmc-maxtablesize=24 --lace-workers=1` configures the decision diagram package
 - `--peak-nodes` makes sure the number of **peak nodes** is printed after reachability analysis.

If you want to run reachability analysis on for example `Vasy2003.pnml`, with a reordering run on the bipartite graph with Sloan, run: `pnml2lts-sym Vasy2003.pnml -rsc,bg,bs,hf --saturation=sat-like --order=chain --next-union --vset=lddmc --lddmc-cachesize=24 --lddmc-maxcachesize=24 --lddmc-tablesize=24 --lddmc-maxtablesize=24 --lace-workers=1 --peak-nodes`. Running this commandline should give output similar to https://github.com/utwente-fmt/BW-NFM2016/blob/master/reach-data/job-1657892.log.

Miscellaneous
--

- The running example in our paper, is in the file `example.pnml`. You can run reorderings on this file if you like.
- The files `pnml/TokenRing-50-unfolded.pnml`, `pnml/galloc_res-5.pnml`, `pnml/shared_memory-pt-200.pnml`, `pnml/distributeur-01-unfolded-10.pnml` are too large to put in this git repository, if needed download them manually from: http://mcc.lip6.fr/models.php.

2. Data analysis
-

Prerequisites
--
To peform the same analysis on the data set from our benchmark, R >= 3.2 is required: https://www.r-project.org.
Additionally the following R packages are required (see http://www.r-bloggers.com/installing-r-packages):
 - ggplot2
 - plyr
 - reshape2
 - scales
 - data.table
 - doMC
 - grid

Data analysis
--
You can do data analysis on our reordering experiments and our reachability experiments.

### Analysis of reordering data

The file `data.csv` contains all relevant LTSmin output from *141054* experiments.
To analyse the data, download `data.csv` and run `Rscript analysis.r data.csv`. This produces several files.
 1. `score-<language>.pdf` plots of the Mean Standard Scores (MSSs) for all five languages, plus the MSSs for all languages combined.
 1. `plot_data-<language>.csv` the csv file with MSS of the above mentioned plots.
 1. `score-legend.pdf` the legend of all plots.
 1. `scatter-<language>-<reordering>.pdf` some scatterplots showing breakdowns of **Weighted Event Span** (WES) for a `language` between several `reordering` algorithms.

### Analysis of reachability data
The file `data-reach.csv` contains all relevant LTSmin output from *17962* experiments run on Petri nets.
To analyse the data, download `data-reach.csv` and run `Rscript analysis-reach.r data-reach.csv`. This commandline produces two files, `score-reach-PNML.pdf` is a plot of the Mean Standard Score (MSS) for *peak nodes*, *WES* and *time*. The file `plot_data-reach-PNML.csv` contains the actual MSS values for the plot.

Parsing LTSmin output
--

You can manually parse the raw stderr/stdout output from LTSmin for the reordering experiments and reachability experiments.

### Parsing data from reordering experiments

The folder `data` contains all the data from the *141054* experiments. We ran our experiments with a time limit of 60 minutes and 4GB of memory. For every benchmark, there is 1 run for statistics and 10 runs for performance.
To convert all LTSmin output to a `csv` file, run: `sh ltsmin2csv.sh data > my-data.csv`.
__This can take a very long time__, since all files have to be parsed with `awk` and `grep`.
When completed, the above mentioned `analysis.r` can be run on `my-data.csv`.

### Parsing data from reachability experiments.

The folder `reach-data` contains all data from the *17962* reachability experiments. We ran these experiments with a time limit of 30 minutes and 4GB of memory. For every benchmark there is 1 run for statistics and 3 runs for performance.
To convert all LTSmin output to a `csv` file, run: `sh ltsmin2csv-reach.sh reach-data > my-data-reach.csv`.
When completed, the above mentioned `analysis-reach.r` can be run on `my-data-reach.csv`.


3. Dependency matrix 2 scatter plot
-
LTSmin can print the dependency matrix to stdout. For larger matrices these are not human readable. We offer scripts that can convert dependency matrices to scatter plots, with R. These scatter plots *are* human readable.

Prerequisites
--
For installing R and packages see Section 2 in this readme. The following extra R packages are needed.
 - cowplot
 - tools

Converting matrices with R
--
To obtain a human readable dependency matrix of, say Vasy2003.pnml, perform the following steps.

1. Download `spec/PNML/Vasy2003.pnml`, `mtrx2csv` and `csv2mtrx.r`. Make sure `mtrx2csv` is executable (`chmod +x mtrx2csv`).
1. To generate the matrix, convert it to CSV with coordinates and then to pdf, run `pnml2lts-sym Vasy2003.pnml --matrix | sh mtrx2csv | Rscript csv2mtrx.r Vasy2003-matrix`. This produces `Vasy2003-matrix.pdf` and can be viewed with a PDF viewer.
1. To generate a reordered matrix, say, with Boost's Sloan implementation, run `pnml2lts-sym Vasy2003.pnml --matrix -rsc,bs | sh mtrx2csv | Rscript csv2mtrx.r Vasy2003-matrix-bs`.
