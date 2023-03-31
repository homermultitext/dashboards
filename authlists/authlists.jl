# Run this dashboard from the root of the
# github repository:
using Pkg
Pkg.activate(joinpath(pwd(), "authlists"))
Pkg.resolve()
Pkg.instantiate()



DASHBOARD_VERSION = "0.3.2"
# Variables configuring the app:  
#
#  1. location  of the assets folder (CSS, etc.)
#  2. port to run on
# 
# Set an explicit path to the `assets` folder
# on the assumption that the dashboard will be started
# from the root of the gh repository!
assets = joinpath(pwd(), "authlists", "assets")
DEFAULT_PORT = 8052
NAMES_URL = "https://raw.githubusercontent.com/homermultitext/hmt-authlists/master/data/hmtnames.cex"

dataurl = "https://raw.githubusercontent.com/homermultitext/hmt-archive/master/releases-cex/hmt-current.cex"

using Dash
using Downloads
using CSV, DataFrames
using CitableObject, CitableObject.CexUtils
using CiteEXchange


NAMES = Cite2Urn("urn:cite2:hmt:pers.v1:")
PLACES = Cite2Urn("urn:cite2:hmt:place.v1:")

function loadauthlists(url)
    cexsrc = Downloads.download(url) |> read |> String
    libinfo = blocks(cexsrc, "citelibrary")[1]
    infoparts = split(libinfo.lines[1], "|") 


    perstuples = []
    for ln in collectiondata(cexsrc, NAMES)
        cols = split(ln, "|")
        push!(perstuples, ( label = cols[4], urn = cols[1], description = cols[5], status = cols[6], redirect = cols[7]))
    end

    placetuples = []
    for ln in collectiondata(cexsrc, PLACES)
        cols = split(ln, "|")
        push!(placetuples, (label = cols[2], urn = cols[1], description = cols[3], status = cols[5], redirect = cols[6]))
    end

    (DataFrame(perstuples), DataFrame(placetuples), infoparts[2])
end

(namesdf, placesdf, versioninfo) = loadauthlists(dataurl)


app = if haskey(ENV, "URLBASE")
    dash(assets_folder = assets, url_base_pathname = ENV["URLBASE"])
else 
    dash(assets_folder = assets)    
end


#app = dash(external_stylesheets=external_stylesheets)

app.layout = html_div([
    dcc_markdown("""
    *Dashboard version*: **$(DASHBOARD_VERSION)** ([version notes](https://homermultitext.github.io/dashboards/authlists/))
    
          
    *Data version*: **$(versioninfo)** ([source](https://raw.githubusercontent.com/homermultitext/hmt-archive/master/releases-cex/hmt-current.cex))
    """),
    html_h1("Search HMT authority lists"),
    dcc_markdown(
    """
    Search data by filling in a `filter data` value for a column (just below the column heading).
    """

    ),
    
    
    dcc_tabs(id="authoritylists", value="persons", children=[
        dcc_tab(label="Personal names", value="persons"),
        dcc_tab(label="Place names", value="places"),
    ]),
    html_div(id="authlisttable")
])

callback!(app,
    Output("authlisttable", "children"),
    Input("authoritylists", "value")
) do tab
    if tab == "persons"
        return html_div([
            html_h3("Personal names"),
            dash_datatable(
                id="namestable",
                columns=[Dict("name" =>i, "id" => i) for i in names(namesdf)],
                data = Dict.(pairs.(eachrow(namesdf))),
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
        ])
    elseif tab == "places"
        return html_div([
            html_h3("Place names"),
            dash_datatable(
                id="placestable",
                columns=[Dict("name" =>i, "id" => i) for i in names(placesdf)],
                data = Dict.(pairs.(eachrow(placesdf))),
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
        ])
    end
end

run_server(app, "0.0.0.0", DEFAULT_PORT, debug=true)