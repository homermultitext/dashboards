# Run this dashboard from the root of the
# github repository:
using Pkg
if  ! isfile("Manifest.toml")
    Pkg.activate(".")
    Pkg.instantiate()
end


DASHBOARD_VERSION = "0.2.0"
# Variables configuring the app:  
#
#  1. location  of the assets folder (CSS, etc.)
#  2. port to run on
# 
# Set an explicit path to the `assets` folder
# on the assumption that the dashboard will be started
# from the root of the gh repository!
assets = joinpath(pwd(), "iliad-browser", "assets")
DEFAULT_PORT = 8052
NAMES_URL = "https://raw.githubusercontent.com/homermultitext/hmt-authlists/master/data/hmtnames.cex"

using Dash
using Downloads, CSV, DataFrames


df = CSV.File(Downloads.download(NAMES_URL), delim = "|", header = 2) |> DataFrame





external_stylesheets = ["https://codepen.io/chriddyp/pen/bWLwgP.css"]
app = if haskey(ENV, "URLBASE")
    dash(assets_folder = assets, url_base_pathname = ENV["URLBASE"])
else 
    dash(assets_folder = assets)    
end

app.layout = html_div() do
    dcc_markdown("""
    *Dashboard version*: **$(DASHBOARD_VERSION)**
    
          
    *Data version*: **current main branch of [github repository](https://github.com/homermultitext/hmt-authlists)**
    """),
    html_h1("Search HMT authority lists:  personal names"),
    dcc_markdown(
    """
    Search data by filling in a `filter data` value for a column (just below the column heading).
    """

    ),
    
    dash_datatable(
        id="namestable",
        columns=[Dict("name" =>i, "id" => i) for i in names(df)],
        data = Dict.(pairs.(eachrow(df))),
        filter_action="native",
        sort_action="native",
        sort_mode="multi",
        column_selectable="single",
        row_selectable="multi",
        selected_columns=[],
        selected_rows=[],
        page_action="native",
        page_current= 0,
        page_size= 10
    )
end

run_server(app, "0.0.0.0", DEFAULT_PORT, debug=true)