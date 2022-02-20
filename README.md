# Homer Multitext project: dashboards

This repository hosts interactive dashboards written wtih [Dash.jl](https://dash.plotly.com/julia) that you can use to explore the contents of published releases of the HMT project archive.  

## Available dashboards

1. `thermometer/thermometer.jl` (default port: `8060`):  automatically composed overview of the contents of the current publihsed release of the HMT archive.
1. `alpha-search/alpha-search.jl` (default port: `8050`):  simple alphabetic search of Greek texts in the HMT archive.  Filter by manuscript and/or text.
1. `codex-browser/codex-browser.jl` (default port: `8051`): visual browser of photographed and documented codices in the HMT archive.
    - `codices+local/codex-browser.jl` (default port: `8054`): a version of the `codex-browser.jl` that allows you to include a collection of cataloged local files
1. `authlists/authlists.jl` (default port: `8052`):  searchable tables of authority lists
1. `iliad-browser/iliad-browser.jl` (default port: `8053`): browser manuscript images by *Iliad* reference.


## Plannned dashboards (in progress work)

1. `lightbox/lightbox.jl` (default port: `8054`): paged browsing of image collections.


## Running the dashboards

### Prequisites

- internet access (the current dashboards download a release of the HMT archive; future versions may allow you to load data from a local file)
- [Julia](https://julialang.org)


The dashboards expect to be started from the root directory of this repository.  You can start them from the command line or from [Visual Studio Code](https://code.visualstudio.com).

### Starting from VS Code

Make sure you have the Julia plugin installed.

1. open this repository, and find the dashboard you want to run
2. option-click anywhere in the file


### From the command line

`julia --project="." PATH/TO/DASHBOARD`

### Viewing the dashboard

By default, the dashboards run on the port number listed above.  Open a browser to `http://localhost:PORT_NUMBER`.
