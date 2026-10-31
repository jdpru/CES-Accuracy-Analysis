<a id="readme-top"></a>

<br />
<div align="center">
  <a href="https://github.com/jdpru/CES-Accuracy-Analysis">
    <img src="PPRG Logo.png" alt="PPRG Logo">
  </a>

  <h3 align="center">CES Accuracy Analysis</h3>

  <p align="center">
    Accuracy of the Cooperative Election Study (2006–2022) under multiple weighting scenarios, with analysis in R and figures in Python.
    <br /><br />
    <a href="https://github.com/jdpru/CES-Accuracy-Analysis">View Repo</a>
  </p>
</div>




<!-- TABLE OF CONTENTS -->
<details open>
  <summary>Table of Contents</summary>
  <ol>
    <li><a href="#overview">Overview</a></li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#clone-the-repo">Clone the repo</a></li>
        <li><a href="#download-ces-data">Download CES data</a></li>
        <li><a href="#get-an-ipums-api-key">Get an IPUMS API Key</a></li>
        <li><a href="#open-the-ces-accuracy-analysisrproj-file">Open the CES Accuracy Analysis.Rproj file</a></li>
        <li><a href="#install-necessary-packages">Install Necessary Packages</a></li>
        <li><a href="#adjust-root-directory-in-setup-chunk">Adjust Root Directory in Setup Chunk</a></li>
        <li><a href="#run">Run</a></li>
      </ul>
    </li>
    <li><a href="#building-the-paper">Building the Paper</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>




<!-- OVERVIEW -->
## Overview

This project calculated the accuracy of the Cooperative Election Study (CES) from 2006 to 2022 using election returns. It did so under various weighting scenarios: unweighted, using the CES-provided weights, and using a custom set of weights generated with ANESRake according to marginal demographic distributions from the Current Population Survey (CPS). 

After cloning the repo (instructions below), you will see a top-level directory with the following sub-directories: `code`, `data`, `tables_and_figures`, and `renv`. The paper itself is two LaTeX documents at the top level, `manuscript.tex` and `supplementary_material.tex`.

The pipeline has two stages, and the paper is built from their output:

1. **`code/analysisHQ.Rmd`** (R Markdown) does the recoding and analysis. It can be run straight through, and it writes four summary tables to `tables_and_figures/input_tables/`: `metrics_base.xlsx`, `most_specific.xlsx`, `national_errors.xlsx`, and `vars_used_by_anesrake.xlsx`.
2. **`tables_and_figures/figuresHQ.ipynb`** (Python, Jupyter) reads `input_tables/` and builds every table, figure, and in-text number the paper uses. Its cells follow the paper's order, and its headings use the paper's table and figure numbers. Output goes to `tables_and_figures/output/`:
   - `output/main/`: tables and figures loaded by `manuscript.tex`.
   - `output/supplementary/`: tables and figures loaded by `supplementary_material.tex`.
   - `output/prose_numbers.tex`: LaTeX macros for the numbers quoted in the text. Both documents load it.

`tables_and_figures/` also holds one more notebook and two folders:

- **`additionalFiguresHQ.ipynb`** is optional and for reference only: exhibits dropped from the paper, earlier versions, robustness checks, and exploratory analyses. Nothing in the paper loads its output (see [Run](#run)).
- **`process_diagram/`** holds `process_diagram.pdf` (Figure 1, the CES sampling and weighting schematic) and the source to rebuild it. It has its own README.
- **`guide_evidence/`** holds `evidence01.png` through `evidence12.png`, screenshots from CES guides used in the Supplementary Material.

<p align="right">(<a href="#readme-top">back to top</a>)</p>


<!-- GETTING STARTED -->
## Getting Started

### Clone the repo
1. Clone the repo
   ```sh
   git clone https://github.com/jdpru/CES-Accuracy-Analysis.git
   ```
### Download CES data
2. CES data should be downloaded from the CES Dataverse. The Dataverse can be accessed [directly](https://dataverse.harvard.edu/dataverse/cces), though the search can be finicky. [Tufts CES data downloads](https://tischcollege.tufts.edu/research-faculty/research-centers/cooperative-election-study/data-downloads-and-tools-scholars) (under "Download CES Datasets and Documentation") link to each year's release.
3. Each year's file should be placed in CES Accuracy Analysis/data/CES Data. The CES occasionally releases updates, so just ensure that the name of each file matches whatever is being loaded in the "CES Datasets" chunk of analysisHQ.Rmd.


### Get an IPUMS API Key
4. I use the IPUMS API to download the relevant CPS data. A free key can be acquired at [https://developer.ipums.org/docs/v2/get-started/](https://developer.ipums.org/docs/v2/get-started/).
5. Place this key as a string into the variable `USER_IPUMS_API_KEY` in analysisHQ.Rmd. CPS data can also be [downloaded manually from IPUMS](https://cps.ipums.org/cps-action/variables/group) if preferred.

### Open the CES Accuracy Analysis.Rproj file
6. This should recreate the R environment and set up your working directory properly
Opening the project uses [renv](https://rstudio.github.io/renv/) to restore the package environment. See the renv docs if you run into environment issues.

### Install necessary packages
7. If you don't already have any of the required packages, uncomment the following lines in the top of analysisHQ, which will install any missing packages. 
```sh
# This downloads any necessary packages
# if (any(pckgs %notin% rownames(installed.packages())==TRUE)){
# install.packages(pckgs, repos = c(CRAN = "http://cloud.r-project.org"))}
```

### Adjust Root Directory in Setup Chunk
8. If you are not running from the opened .Rproj (e.g. running from a different working directory), set the root at the top of **analysisHQ.Rmd**:
```r
knitr::opts_knit$set(root.dir = '/path/to/your/CES Accuracy Analysis')
```

### Run
Once the environment is set up, run the pipeline in this order:

9. **`analysisHQ.Rmd`** (in `code/`) can be run from top to bottom. It writes four tables to `tables_and_figures/input_tables/`.

10. **`figuresHQ.ipynb`** (in `tables_and_figures/`) can then be run from top to bottom. It reads from `input_tables/` and writes the paper's tables, figures, and in-text number macros to `tables_and_figures/output/` (`main/`, `supplementary/`, and `prose_numbers.tex`). Running it creates the `output/` subfolders. `output/` is git-ignored, so it will not appear in a fresh clone.

11. Optional: **`additionalFiguresHQ.ipynb`** (in `tables_and_figures/`) is for reference only. Its first cell runs `figuresHQ.ipynb`, so the requirements for step 10 apply. It then writes everything to `tables_and_figures/output/additional/`. Nothing in the paper loads these files.

<p align="right">(<a href="#readme-top">back to top</a>)</p>


<!-- BUILDING THE PAPER -->
## Building the Paper

The paper is `manuscript.tex` and `supplementary_material.tex`, both at the repo root. They cross-reference each other with the `xr-hyper` package, so each needs the other's `.aux` file. The `latexmkrc` at the root makes `latexmk` build the other document first, so build with `latexmk`. The bibliography is `CESBib.bib` (biblatex).

To compile (for example on Overleaf), the project root needs:

- `manuscript.tex`
- `supplementary_material.tex`
- `CESBib.bib`
- `latexmkrc`
- `output/prose_numbers.tex`
- `output/main/`
- `output/supplementary/`
- `process_diagram/process_diagram.pdf`
- `guide_evidence/`

In the repo, `output/`, `process_diagram/`, and `guide_evidence/` live under `tables_and_figures/`. Copy them to the root of the compile directory. `output/additional/` is not needed.

<p align="right">(<a href="#readme-top">back to top</a>)</p>


<!-- LICENSE -->
## License

Distributed under the MIT License. See `LICENSE` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>


<!-- CONTACT -->
## Contact

Jefferson (JD) Pruett - [https://www.linkedin.com/in/jd-pruett-4033b8194/](https://www.linkedin.com/in/jd-pruett-4033b8194/)

Project Link: [https://github.com/jdpru/CES-Accuracy-Analysis](https://github.com/jdpru/CES-Accuracy-Analysis)

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- ACKNOWLEDGMENTS -->
## Acknowledgments

Thank you Jon Krosnick for advising on this project. 

Ballotpedia provided a large portion of the state-level election data. 

IPUMS harmonized CPS datasets were used. 
Sarah Flood, Miriam King, Renae Rodgers, Steven Ruggles, J. Robert Warren, Daniel Backman, Annie Chen, Grace Cooper, Stephanie Richards, Megan Schouweiler, and Michael Westberry. IPUMS CPS: Version 12.0 [dataset]. Minneapolis, MN: IPUMS, 2024. https://doi.org/10.18128/D030.V12.0


<p align="right">(<a href="#readme-top">back to top</a>)</p>

