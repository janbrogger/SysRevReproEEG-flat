This is a repo for a systematic review of the reproducibility of human visual analysis of extracranial/scalp clinical EEG.

The original protocol for the systematic review is in PROSPERO, here: https://www.crd.york.ac.uk/PROSPERO/view/99318

There is more data than the current contributors can manage, and perhaps some reuse value can be had of the substantial search effort that was made, and to encourage scientific reproducibility and learning.

# Limitations
* This is a subset of the original git repo, containing all the data abstracted from the papers.
* The authors can't provide the PDFs for all the included papers for copyright reasons.
* The field has highly variable data concerning inclusion and clinical context.
* Future users are advised to take advice from experienced clinical EEGers with academic experience in order to make sense of the processes that generated these data.

# Manuscripts related to this repo
One manuscript has been published based on this systematic review:
Aanestad, Eivind, et al. "Unveiling variability: A systematic review of reproducibility in visual EEG analysis, with focus on seizures." Epileptic Disorders 26.6 (2024): 827-839. DOI: 10.1002/epd2.20291

A second manuscript is in press after peer review:
Brogger, Jan et al. "Interictal epileptiform discharges in scalp EEG: reproducibility of visual interpretation. A systematic review"
The manuscript text itself will be added here when it is published; this snapshot contains the data, analysis scripts and generated tables/figures for the revised version.

# Analysis pipeline and data formats
* This repo uses numbered directories and files to illustrate which processes and files are run first
* The results of the literature search and data abstraction are in the subdirectory '2Results'
* A preliminary data cleaning step is in the subdirectory '3CleanData' (with scripts and output)
* The second manuscript's analysis (scripts, figures, tables) is in '6Manuscript2'

# Manuscript directory and script structure
* The second manuscript uses a flowed directory structure, where analysis scripts are in '1script-stata', interim data in '2data', log files in '3log', and script output in '4output'
* '5tosubmit' holds the supplementary tables; '6re-abstract-variables' documents the LLM-assisted re-abstraction (prompts and manually verified data); '97-donselaar' holds the datasets from the van Donselaar 1992 design-correction analysis
* The Stata scripts assume the working directory C:\Midlertidig_Lagring\SysRevReproEeg (adjust the 'cd' line at the top of each script for your own machine)

# To future users
The master list contains all papers identified in this systematic review, including those for data that have not been published yet.
The preliminary data cleaning script produces a feature list (\3CleanData\output\featureList.xlsx) which may be useful.
The Stata scripts give examples of how to read in the abstracted data and create tables and figures.
