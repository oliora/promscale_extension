# Promscale Extension #

This [Postgres extension](https://www.postgresql.org/docs/12/extend-extensions.html)
contains support functions to improve the performance of Promscale.
While Promscale will run without it, adding this extension will
cause it to perform better.

## Requirements ##

To run the extension:
- PostgreSQL version 12 or newer.

To compile the extension (see instructions below):
- Rust compiler
- PGX framework

## Installation ##

### Precompiled OS Packages ###

You can install the promscale extension from extension version 0.3.0 with precompiled deb and rpm packages for Debian and RedHat-based distributions. The packages are available with the GitHub [release](https://github.com/timescale/promscale_extension/releases). The extension builds on Postgres' official packages for each distribution and is compatible with Postgres versions 12, 13, and 14.

#### Debian Derivatives ####

1. Install Postgres
    ```
    apt-get install -y wget gnupg2 lsb-release
    echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
    apt-get update
    apt-get install -y postgresql-14
    ```

2. Install the extension
    ```
    wget https://github.com/timescale/promscale_extension/releases/download/0.3.0/promscale_extension-0.3.0.pg14.x86_64.deb
    dpkg -i promscale_extension-0.3.0.pg14.x86_64.deb
    ```

#### RedHat Derivatives ####

Note: This example is for CentOS 7. Please refer to Postgres' [documentation](https://www.postgresql.org/download/linux/redhat/) if you're using a different version or distribution.

1. Install Postgres
    ```
    yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
    yum install -y postgresql14-server
    ```

2. Install the extension
    ```
    yum install -y wget
    wget https://github.com/timescale/promscale_extension/releases/download/0.3.0/promscale_extension-0.3.0.pg14.x86_64.rpm
    yum localinstall -y promscale_extension-0.3.0.pg14.x86_64.rpm
    ```

### Compile From Source ###

The extension is installed by default on the
[`timescaledev/promscale-extension:latest-pg12`](https://hub.docker.com/r/timescaledev/promscale-extension) docker image.

For bare-metal installations, the full instructions for setting up PostgreSQL, TimescaleDB, and the Promscale Extension are:

1) Install some necessary dependencies
    ```bash
    sudo apt-get install -y wget curl gnupg2 lsb-release
    ```
1) [Add the PostgreSQL APT repository (Ubuntu)](https://www.postgresql.org/download/linux/ubuntu/)
    ```bash
    echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -c -s)-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
    ```
1) Add the TimescaleDB APT repository
    ```bash
    echo "deb [signed-by=/usr/share/keyrings/timescale.keyring] https://packagecloud.io/timescale/timescaledb/ubuntu/ $(lsb_release -c -s) main" | sudo tee /etc/apt/sources.list.d/timescaledb.list
    wget --quiet -O - https://packagecloud.io/timescale/timescaledb/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/timescale.keyring
    ```
1) Install PostgreSQL with TimescaleDB
    ```bash
    sudo apt-get update
    sudo apt-get install -y timescaledb-2-postgresql-14
    ```
1) Tune the PostgreSQL installation
    ```bash
    sudo timescaledb-tune --quiet --yes
    sudo service postgresql restart
    ```
1) Install dependencies for the PGX framework and promscale_extension
    ```bash
    sudo apt-get install -y build-essential clang libssl-dev pkg-config libreadline-dev zlib1g-dev postgresql-server-dev-14
    ```
1) [Install rust](https://www.rust-lang.org/tools/install).
    ```bash
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    source $HOME/.cargo/env
    ```
1) Install the PGX framework
    ```bash
    cargo install cargo-pgx
    ```
1) Initialize the PGX framework using the PostgreSQL 14 installation
    ```bash
    cargo pgx init --pg14=/usr/lib/postgresql/14/bin/pg_config
    ```
1) Download this repo and change directory into it
    ```bash
    curl -L -o "promscale_extension.zip" "https://github.com/timescale/promscale_extension/archive/refs/tags/0.3.0.zip"
    sudo apt-get install unzip
    unzip promscale_extension.zip
    cd promscale_extension-0.3.0
    ```
1) Compile and install
    ```bash
    make
    sudo make install
    ```
1) Create a PostgreSQL user and database for promscale (use an appropriate password!)
    ```bash
    sudo -u postgres psql -c "CREATE USER promscale SUPERUSER PASSWORD 'promscale';"
    sudo -u postgres psql -c "CREATE DATABASE promscale OWNER promscale;"
    ```
1) [Download and run promscale (it will install the extension in the PostgreSQL database)](https://github.com/timescale/promscale/blob/master/docs/bare-metal-promscale-stack.md#2-deploying-promscale)
    ```bash
    LATEST_VERSION=$(curl -s https://api.github.com/repos/timescale/promscale/releases/latest | grep "tag_name" | cut -d'"' -f4)
    curl -L -o promscale "https://github.com/timescale/promscale/releases/download/${LATEST_VERSION}/promscale_${LATEST_VERSION}_Linux_x86_64"
    chmod +x promscale
    ./promscale --db-name promscale --db-password promscale --db-user promscale --db-ssl-mode allow --install-extensions
    ```

This extension will be created via `CREATE EXTENSION` automatically by the Promscale connector and should not be created manually.

## Common Compilation Issues ##

- `cargo: No such file or directory` means the [Rust compiler](https://www.rust-lang.org/tools/install) is not installed
