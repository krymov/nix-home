# Data processing tools — CSV, JSON, SQL, plotting.
{ pkgs }:

with pkgs; [
  # CSV/TSV
  qsv               # fast CSV swiss-army knife (Rust)
  tidy-viewer       # pretty CSV viewer (tv)
  miller            # mlr: awk for CSV/TSV
  csvkit            # csvlook/csvcut/csvjoin (Python)
  csvtk             # fast CSV/TSV toolkit (Go)
  visidata          # interactive TUI data wrangler
  xan               # maintained xsv alternative
  python3Packages.daff  # CSV/TSV table-aware diffs

  # JSON/YAML/TOML (extended)
  gojq              # fast/strict JSON processor
  dasel             # query JSON/YAML/TOML/XML
  fx                # interactive JSON viewer
  jo                # build JSON from shell
  jless             # JSON/YAML viewer with filtering

  # SQL-on-files
  duckdb            # query CSV/Parquet with SQL
  sqlite            # SQLite CLI
  sqlite-utils      # load/query CSVs into SQLite
  datasette         # explore SQLite databases

  # Database clients
  pgcli             # PostgreSQL CLI with autocompletion
  postgresql        # psql
  mongosh           # MongoDB shell
  redis             # redis-cli
  clickhouse        # ClickHouse client
  kcat              # Kafka producer/consumer/metadata
  # usql            # universal SQL client — broken in nixpkgs-unstable (cockroachdb/swiss Go dep)

  # Logs & text pipelines
  angle-grinder     # agrind: structured log queries
  choose            # quick column selector
  datamash          # one-liner aggregations
  parallel          # GNU parallel
  pv                # show pipe throughput
  jc                # turn command output into JSON

  # Spreadsheet & plots
  sc-im             # vim-like terminal spreadsheet
  gnuplot           # quick plots from CSV

  # HTML testing
  htmltest          # link checker for HTML output
]
++ pkgs.lib.optionals pkgs.stdenv.isLinux [
  pg_top            # PostgreSQL monitoring (Linux-only)
]
