# Homer Multitext project: dashboards

This repository hosts interactive dashboards written wtih [Dash.jl](https://dash.plotly.com/julia) that you can use to explore the contents of published releases of the HMT project archive.  

## Available dashboards

1. `alpha-search`:  simple alphabetic search of Greek texts in the HMT archive.  Filter by manuscript and/or text.

## Prequisites

- internet access (the current dashboards download a release of the HMT archive; future versions may allow you to load data from a local file)
- [Julia](https://julialang.org)

## Running the dashboards

The dashboards expect to be started from the root directory of this repository.  You can start them from the command line or from [Visual Studio Code](https://code.visualstudio.com).

### Starting from VS Code

Make sure you have the Julia plugin installed.

1. open this repository, and find the dashboard you want to run
2. option-click anywhere in the file


### From the command line

`julia --project="." PATH/TO/DASHBOARD`

### Viewing the dashboard

By default, the dashboards run on port 8050: open a web browser to  [http://0.0.0.0:8050](http://0.0.0.0:8050).