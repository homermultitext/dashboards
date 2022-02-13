# Run this dashboard from the root of the
# github repository:
using Pkg
if  ! isfile("Manifest.toml")
    Pkg.activate(".")
    Pkg.instantiate()
end


DASHBOARD_VERSION = "0.1.0"

NAMES_URL = "https://raw.githubusercontent.com/homermultitext/hmt-authlists/master/data/hmtnames.cex"

using Dash
using Downloads, CSV, DataFrames

df = CSV.File(Downloads.download(NAMES_URL), delim = "|", header = 2) |> DataFrame


external_stylesheets = ["https://codepen.io/chriddyp/pen/bWLwgP.css"]
app = dash(external_stylesheets=external_stylesheets)

app.layout = html_div() do
    html_h1("Search HMT authority lists:  personal names"),
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

run_server(app, "0.0.0.0", debug=true)