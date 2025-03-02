# phyloGeo

S. Bennett's phyloGeo course GitHub.

# Course Instructions: Phylogeographic Workshop Day 3 – Using Git, GitHub, R, and RStudio

Pick your OS below and follow along to get your computer working for today's lesson. See the 'hint' at the bottom if you are having trouble. For Mac M1 or new (i.e. Mac - Silicon) scroll down, for PC's go to [(Windows)](https://github.com/snbennett/phyloGeo/blob/main/README.md#windows) or scroll way down.

# (Mac - Silicon)

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

# (Windows)

## Step 1: Install Git for Windows

1.  Download Git for Windows from [git-scm.com](https://git-scm.com/download/win).
2.  Run the installer and select the following options:
    -   **Use Git from the Windows Command Prompt**
    -   **Use Windows’ default console window**
    -   **Use credential helper: Manager**
    -   Other default options are fine.
3.  Verify installation:
    -   Open **Command Prompt** or **Git Bash**.

    -   Type:

        ``` bash
        git --version
        ```

    -   You should see a version number if Git installed correctly.

------------------------------------------------------------------------

## Step 2: Install R and RStudio

1.  Download R from [CRAN R Project](https://cran.r-project.org/):
    -   Select the **Windows** version and install it.
2.  Download and install RStudio from [RStudio website](https://posit.co/download/rstudio-desktop/).
3.  Verify installation:
    -   Open RStudio and type:

        ``` r
        version
        ```

    -   You should see version details for R.

------------------------------------------------------------------------

## Step 3: Clone a Repository

1.  Open **Git Bash** (or **Command Prompt** if Git is installed system-wide).

2.  Navigate to your preferred directory:

    ``` bash
    cd C:/Users/YourUsername/Documents
    ```

3.  Clone the repository:

    ``` bash
    git clone https://github.com/ddkapan/phyloGeo
    ```

    *(this is the GitHub repo for the course)*

4.  Navigate into the cloned repository:

    ``` bash
    cd phyloGeo
    ```

------------------------------------------------------------------------

## Step 4: Open Repository in RStudio

1.  Open RStudio.
2.  Click **File \> Open Project...**.
3.  Navigate to the folder where you cloned the repository and select the **.Rproj** file.
4.  Run an R script:
    -   Navigate to the **code** directory.
    -   Open the `phylogenyExample_ape_phytools.R` script.
    -   Run it interactively by pressing **Ctrl + Enter** on each line.

------------------------------------------------------------------------

## Step 5: Quick Hack if Git Is Too Complex

If setting up Git is too complicated, use this workaround:

1.  Go to the GitHub repository: [phyloGeo](https://github.com/ddkapan/phyloGeo).
2.  Navigate to the **code** directory and find the script you want to run.
3.  Click the script filename to open it.
4.  Click the **Copy raw contents** button (clipboard icon) to copy the script.
5.  In RStudio, create a new script: **File \> New File \> R Script**.
6.  Paste the copied script into the new file.
7.  Save the file with the correct name (e.g., `phylogenyExample_ape_phytools.R`).
8.  Run it interactively by pressing **Ctrl + Enter** on each line.

### Why This Isn’t Best Practice

This method works as a quick fix but lacks version control, documentation, and reproducibility. Try to get the **Git workflow** working when you have time to ensure better collaboration and tracking of changes.

------------------------------------------------------------------------

These steps will set up your Windows PC for running R code efficiently. Let me know if you need modifications!
