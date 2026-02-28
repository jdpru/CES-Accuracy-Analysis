<a id="readme-top"></a>

<br />
<div align="center">
  <a href="https://github.com/jdpru/CES-Accuracy-Analysis">
    <img src="PPRG Logo.png" alt="PPRG Logo">
  </a>

  <h3 align="center">CES Accuracy Analysis</h3>

  <p align="center">
    Accuracy of the Cooperative Election Study (2006–2022) under multiple weighting scenarios, with analysis in R and figures in Python.
    <br />
    <a href="https://github.com/jdpru/CES-Accuracy-Analysis#readme"><strong>Explore the docs »</strong></a>
    <br /><br />
    <a href="https://github.com/jdpru/CES-Accuracy-Analysis">View Repo</a>
    &middot;
    <a href="https://github.com/jdpru/CES-Accuracy-Analysis/issues/new?labels=bug">Report Bug</a>
    &middot;
    <a href="https://github.com/jdpru/CES-Accuracy-Analysis/issues/new?labels=enhancement">Request Feature</a>
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
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>




<!-- OVERVIEW -->
## Overview

This project calculated the accuracy of the Cooperative Election Study (CES) from 2006 to 2022 using election returns. It did so under various weighting scenarios: unweighted, using the CES-provided weights, and using a custom set of weights generated with ANESRake according to marginal demographic distributions from the Current Population Survey (CPS). 

After cloning the repo (instructions below), you will see a top-level directory with the following sub-directories: `data`, `code`, `tables_and_figures`, and `renv`. The recoding and analysis are done in R Markdown; tables and figures are produced in Python via a Jupyter notebook. **analysisHQ.Rmd** can be run straight through to recreate the analysis. It writes summary tables (e.g. `metrics_base.xlsx`, `most_specific.xlsx`, `national_errors.xlsx`, `vars_used_by_anesrake.xlsx`) to **tables_and_figures/input_tables/**, which **figuresHQ.ipynb** then reads to produce all final figures and tables. 

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
Once the environment is set up, you can run the entire analysis as follows:
9. **`analysisHQ.Rmd`** (in `code/`) can be run from top to bottom. It writes summary tables to `tables_and_figures/input_tables/`.

10. **`figuresHQ.ipynb`** (in `tables_and_figures/`) can then be run from top to bottom. It reads from `input_tables/` and saves figures and tables to `tables_and_figures/output/`.

<!-- LICENSE -->
## License

Distributed under the MIT License. See `LICENSE.txt` for more information.

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


