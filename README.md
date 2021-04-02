Script to extract data from JIRA and pull it into a postgres DB for analysis.

## Setup

1. Install [docker][docker-desktop]
2. Install [nim][nimlang] (via [choosenim][choosenim]).
3. [Generate an API token for your JIRA user.][jira-api-key]
4. Pull the database container:

   ```sh
   make createdb
   ```

   Feel free to edit the Makefile to view or change the default
   username/password combination.

4. Build the tool:

   ```sh
   nimble build
   ```

## Usage

- Start the database container:

  ```sh
  make startdb
  ```

- Pull issues from your JIRA instance into the DB:

  ```sh
  ./jira_analysis api-sync <jira-base-url> <username> <api-token>
  ```

- Connect to the database for analysis:

  ```sh
  make connect
  ```

## Convenient PostgreSQL commands

From within a `psql` session:

- Export tables to CSV:

  ```psql
  \copy features TO features-export.csv DELIMITER ',' CSV HEADER;
  \copy issues TO issues-export.csv DELIMITER ',' CSV HEADER;
  \copy change_logs TO changelog-export.csv DELIMITER ',' CSV HEADER;
  ```

[docker-desktop]: https://www.docker.com/products/docker-desktop
[nimlang]: https://nim-lang.org/
[choosenim]: https://github.com/dom96/choosenim
[jira-api-key]: https://support.atlassian.com/atlassian-account/docs/manage-api-tokens-for-your-atlassian-account/
