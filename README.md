# phyloGeo

S. Bennett's phyloGeo course GitHub.

# Course Instructions: Phylogeographic Workshop Day 3 – Using Git, GitHub, R, and RStudio

## Step 1: Install Xcode

Xcode is required for compiling and installing certain packages in R. To install Xcode:

1.  Open **Terminal** (found in Applications \> Utilities \> Terminal).

2.  Type the following command and press **Enter**:

    ``` bash
    xcode-select --install
    ```

3.  Follow the on-screen instructions to complete the installation.

4.  Verify the installation by running:

    ``` bash
    xcode-select --version
    ```

    You should see a version number if Xcode is installed correctly.

------------------------------------------------------------------------

## Step 2: Install R and RStudio

To work with R, you need to install both the R language and the RStudio IDE.

1.  Download and install R:
    -   Visit [CRAN R Project](https://cran.r-project.org/).
    -   Click **Download R for macOS** and install the `.pkg` file.
2.  Download and install RStudio:
    -   Visit [RStudio website](https://posit.co/download/rstudio-desktop/).
    -   Download the **macOS** version and install it by dragging it to the Applications folder.
3.  Verify the installation:
    -   Open RStudio and type:

        ``` r
        version
        ```

    -   You should see version details for R.

------------------------------------------------------------------------

## Step 3: Check for Git

Git is used for version control and working with repositories.

1.  Open **Terminal**.

2.  Type:

    ``` bash
    git --version
    ```

3.  If Git is installed, you’ll see a version number. If not, install it with:

    ``` bash
    brew install git
    ```

    *(If Homebrew is not installed, install it first:* \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*`/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*)\*

------------------------------------------------------------------------

## Step 4: Manually Clone a Repository

To clone an existing repository from GitHub:

1.  In **Terminal**, navigate to the desired directory:

    ``` bash
    cd ~/GitHub # I use GitHub, keeps things in one place
    ```

2.  Clone the repository:

    ``` bash
    git clone https://github.com/ddkapan/phyloGeo
    ```

    *(this is the GitHub we put together for this week’s course)*

3.  Navigate into the cloned repository:

    ``` bash
    cd phyloGeo
    ```

------------------------------------------------------------------------

## Step 5: Open Repository in RStudio

1.  Open RStudio.
2.  Click **File \> Open Project...**.
3.  Navigate to the folder where you cloned the repository and select the **.Rproj** file.
4.  Run an R script:
    -   Navigate to the **code** directory.
    -   Open the `phylogenyExample_ape_phytools.R` script.
    -   Run it interactively by hitting **Cmd + Enter** on each line.

## Step 6: Quick Hack if This is Too Complex

If the Git process is too complicated for now, you can use this workaround:

1.  Go to the GitHub repository: [phyloGeo](https://github.com/snbennett/phyloGeo).
2.  Navigate to the **code** directory and locate the script you want to run.
3.  Click on the script filename to open it.
4.  Click the **Copy raw contents** button (clipboard icon) to copy the script.
5.  In RStudio, create a new script: **File \> New File \> R Script**.
6.  Paste the copied script into the new file.
7.  Save the file with the correct name (e.g., `phylogenyExample_ape_phytools.R`).
8.  Run it interactively by pressing **Cmd + Enter** on each line.

### Why This Isn’t Best Practice

This method works as a quick fix but lacks version control, documentation, and reproducibility. In your own time, try to get the **Git workflow** to work so you can track changes, collaborate efficiently, and manage your scripts properly.
