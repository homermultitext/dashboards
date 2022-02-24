# Explore the Homer Multitext archive with interactive dashboards

You can use reactive dashboards in your web browser to explore the current published release of the Homer Multitext project's data archive.  

## Hosted on [homermultitext.org](https://www.homermulitextorg)

### Status of the archive

1. [thermometer](https://www.homermultitext.org/thermometer/):  an automatically composed overview of the contents of the current published release of the HMT archive.

### Explore contents of the archive

1. [alpha-search](https://www.homermultitext.org/alpha-search):  simple alphabetic search of Greek texts in the HMT archive.  Filter by manuscript and/or text.
1. [codex-browser](https://www.homermultitext.org/codex-browser): visual browser of photographed and documented codices in the HMT archive.
 1. lightbox (TBA): paged browsing of image collections..  
1. [iliad-browser](https://www.homermultitext.org/iliad-browser): browse indexed manuscript images by *Iliad* reference.

### Reference lists

1. [authlists](https://www.homermultitext.org/authlists):  searchable tables of authority lists




## Running dashboards locally

If you install [Julia](https://julialang.org), you can run any of the dashboards locally when you're online. (The current dashboards download a release of the HMT archive over the internet; future versions may allow you to load data from a local file.)

The dashboards expect to be started from the root directory of this repository.  You can start them from the command line or from [Visual Studio Code](https://code.visualstudio.com).


### Starting from VS Code

Make sure you have the Julia plugin installed.

1. open this repository, and find the dashboard you want to run
2. option-click anywhere in the file


### Starting from the command line

The following list of "Available Dashboards" tells you the path to each dashboard and the port it expects to run on.  You can start the dashboard with:

`julia --project="DASHBOARD_DIRECTORY" FULL_PATH/TO/DASHBOARD`

For example, you can start the `alpha-search` dashboard with

`julia --project=alpha-search alpha-search/alpha-search.jl`

### Viewing the dashboard

By default, the dashboards run on the port number listed below.  Open a browser to `http://localhost:PORT_NUMBER`.



### Available dashboards

#### Status of the archive

1. `thermometer/thermometer.jl` (default port: `8060`):  automatically composed overview of the contents of the current published release of the HMT archive.

#### Explore contents of the archive

1. `alpha-search/alpha-search.jl` (default port: `8050`):  simple alphabetic search of Greek texts in the HMT archive.  Filter by manuscript and/or text.
1. `codex-browser/codex-browser.jl` (default port: `8051`): visual browser of photographed and documented codices in the HMT archive.
    - `codices+local/codex-browser.jl` (default port: `8054`): a version of the `codex-browser.jl` that allows you to include a collection of cataloged local files
1. `lightbox/lightbox.jl` (default port: `8055`): paged browsing of image collections..    
1. `iliad-browser/iliad-browser.jl` (default port: `8053`): browse manuscript images by *Iliad* reference.


#### Reference lists

1. `authlists/authlists.jl` (default port: `8052`):  searchable tables of authority lists



