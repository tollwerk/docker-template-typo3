# docker-template-typo3

The files in this repository are meant to be used as the starting point for a new TYPO3 project based on the [Tollwerk Docker images](https://github.com/tollwerk/docker-tollwerk). Apart from a working Docker setup, only two files are necessary to kickstart a new project following this setup:

* [docker-compose.yml](docker-compose.yml) to download and initialize the Docker images. The [tollwerk/typo3](https://github.com/tollwerk/docker-tollwerk/blob/master/typo3/README.md) image is kinda "self-extracting" and will take care of the installation process.
* [.env.example](.env.example) which will serve as template for a project specific environment file (`.env`)  you will have to craft before starting the Docker containers for the first time.

## Project kick-off

Before you can start working on your project on potentially many development machines, you have to create and configure an **original instance** which will also be used for your initial Git commit.

On the command line of your machine, change to the directory where your project should live and **create a shallow clone** of this repository (replace `<new_project_name>` accordingly):

1. Navigate to your **project's parent directory**.
    ```
    cd /path/to/project/parent
    ```
2. Create a **shallow clone** of this repository (replace `<new_project_name>`).
    ```
    git clone --depth=1 https://github.com/tollwerk/docker-template-typo3.git <new_project_name>
    ```  
3. Remove the tracking link to the original template repository.
    ```
    git remote remove origin
    ```
4. Reset ownership to yourself.
    ```
    git commit --amend --reset-author -m "Initial Commit"
    ```
   
## Configuration & installation

1. Rename the `.env.example` to `.env` and edit the environment variables inside to match your project requirements.
2. Let Docker bring up the containers and install the rest of the project.
    ```
    docker compose
    ```
   
## Push to a remote repository

1. Create a new online repository for your project.
2. Copy the unique URL for your new repository to your clipboard.
3. In your local repository, from the command line, add the remote tracking information for the new repository.
    ```
    git remote add origin <new_project_repo_URL>
    ```
4. Push to a branch (usually `master`).
    ```
    git push --set-upstream origin master
    ```
