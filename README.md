<!-- Improved compatibility of back to top link: See: https://github.com/othneildrew/Best-README-Template/pull/73 -->
<a id="readme-top"></a>
<!--
-->



<!-- PROJECT SHIELDS -->
<!--
*** I'm using markdown "reference style" links for readability.
*** Reference links are enclosed in brackets [ ] instead of parentheses ( ).
*** See the bottom of this document for the declaration of the reference variables
*** for contributors-url, forks-url, etc. This is an optional, concise syntax you may use.
*** https://www.markdownguide.org/basic-syntax/#reference-style-links
-->

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/jdpru/CES-Accuracy-Analysis">
    <img src="PPRG Logo.png" alt="PPRG Logo">
  </a>

  <h3 align="center">CES Accuracy Analysis</h3>

  <p align="center">
    A README.
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

After cloning the repo (instructions below), you will see a top-level directory with the following sub-directories: data, code, tables_and_figures, and renv. The recoding and analysis is done in R Markdown, while most of the tables and all of the figures are done in Python with a jupyter notebook. **analysisHQ.Rmd** can be run straight through to recreate all the analysis. The primary output is an excel file called **partitioned_accuracy_results.xlsx** which serves as the primary input for **figuresHQ.ipynb**. 

<p align="right">(<a href="#readme-top">back to top</a>)</p>


<!-- GETTING STARTED -->
## Getting Started

### Clone the repo
1. Clone the repo
   ```sh
   git clone (https://github.com/jdpru/CES-Accuracy-Analysis.git)
   ```
### Download CES data
2. CES data should be downloaded from the CES Dataverse. The Dataverse can be accesed [directly](https://dataverse.harvard.edu/dataverse/cces), though I've found the search functionality to be a bit finnicky. I'd recommend using [these links](https://tischcollege.tufts.edu/research-faculty/research-centers/cooperative-election-study/data-downloads-and-tools-scholars) to each year's release from Tufts, which can be found under "Download CES Datasets and Documentation".
3. Each year's file should be placed in CES Accuracy Analysis/data/CES Data. The CES occasionally releases updates, so just ensure that the name of each file matches whatever is being loaded in the "CES Datasets" chunk of analysisHQ.Rmd.


### Get an IPUMS API Key
4. I use the IPUMS API to download the relevant CPS data. A free key can be acquired at [https://developer.ipums.org/docs/v2/get-started/](https://developer.ipums.org/docs/v2/get-started/).
5. Place this key as a string into the variable `USER_IPUMS_API_KEY` in analysisHQ. The CPS data can also be downloaded manually off the IPUMS site [https://cps.ipums.org/cps-action/variables/group](here), if this is preferred.

### Open the CES Accuracy Analysis.Rproj file
6. This should recreate the R environment and set up your working directory properly
Note that Rproj should use [renv](https://rstudio.github.io/renv/) to recreate the package environmemnt. See their documentation if you have any environment issues.

### Install necessary packages
7. If you don't already have any of the required packages, uncomment the following lines in the top of analysisHQ, which will install any missing packages. 
```sh
# This downloads any necessary packages
# if (any(pckgs %notin% rownames(installed.packages())==TRUE)){
# install.packages(pckgs, repos = c(CRAN = "http://cloud.r-project.org"))}
```

### Adjust Root Directory in Setup Chunk
8. At the top of AnalysisHQ.Rmd, replace the following with your root directory
```sh
knitr::opts_knit$set(root.dir = '/path/to/your/CES Accuracy Analysis')
```

### Run
Once the environment is set up, you can run the entire analysis as follows:
9. **`analysisHQ.Rmd`** (located in the `code/` directory) can be run from top to bottom.
   * This script generates all necessary summary tables and saves them to `tables_and_figures/input tables/`.

10. **`figuresHQ.ipynb`** (located in `tables_and_figures/`) can then be run from top to bottom.
   * It reads in the input tables and produces all final figures, which are saved to `tables_and_figures/output figures/`.

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



<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[contributors-shield]: https://img.shields.io/github/contributors/othneildrew/Best-README-Template.svg?style=for-the-badge
[contributors-url]: https://github.com/othneildrew/Best-README-Template/graphs/contributors

