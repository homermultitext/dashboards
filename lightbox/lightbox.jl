# Run this dashboard from the root of the
# github repository:
using Pkg
Pkg.activate(joinpath(pwd(), "lightbox"))
Pkg.instantiate()

DASHBOARD_VERSION = "0.2.4"
# Variables configuring the app:  
#
#  1. location  of the assets folder (CSS, etc.)
#  2. port to run on
# 
# Set an explicit path to the `assets` folder
# on the assumption that the dashboard will be started
# from the root of the gh repository!
assets = joinpath(pwd(), "lightbox", "assets")
DEFAULT_PORT = 8055

using Dash
using CitableBase
using CitableObject
using CitableObject.CexUtils
using CitableImage
using CiteEXchange
using Downloads
using Tables
using HmtArchive, HmtArchive.Analysis

baseiiifurl = "http://www.homermultitext.org/iipsrv"
iiifroot = "/project/homer/pyramidal/deepzoom"
ict = "http://www.homermultitext.org/ict2/?"
iiifservice = IIIFservice(baseiiifurl, iiifroot)

"""Construct a table of image collections, and release info.
"""
function loadhmtdata()
    src = hmt_cex()
    imgs = hmt_images(src)
    (imgs, hmt_releaseinfo(src))
end
#(imagecollections, imagecites, releaseinfo) = loadhmtdata()
(imagecollections, releaseinfo) = loadhmtdata()

"""Compose radio options for selecting image collection."""
function collectionmenu(citepairs)
    opts = []
    for cite in citepairs
        push!(opts, (label = cite.label, value = string(cite.urn)))
    end
    opts
end

app = if haskey(ENV, "URLBASE")
    dash(assets_folder = assets, url_base_pathname = ENV["URLBASE"])
else 
    dash(assets_folder = assets)    
end



app.layout = html_div(className = "w3-container") do
    html_div(className = "w3-container w3-light-gray w3-cell w3-mobile w3-leftbar w3-border-gray",
        children = [dcc_markdown("*Dashboard version*: **$(DASHBOARD_VERSION)** ([version notes](https://homermultitext.github.io/dashboards/lightbox/))")]),

    html_div(className = "w3-container w3-pale-yellow w3-cell  w3-mobile w3-leftbar w3-border-yellow",
        children = [dcc_markdown("*Data version*: **$(releaseinfo)** ([source](https://raw.githubusercontent.com/homermultitext/hmt-archive/master/releases-cex/hmt-current.cex))")]),


    html_h1() do 
        dcc_markdown("HMT project: browse image collections")
    end,
    dcc_markdown("""Browse tables of **$(length(imagecollections))** image collections 
    cataloging a total of **$(length.(imagecollections) |> sum)** images.
    """),


    html_h2("Format table"),
    html_div(className="w3-container",
        children = [
        html_div(className="w3-col l4 m4",
            children = [
                "Number of columns",
                dcc_slider(                    
                    id="columns",
                    min=4,
                    max=10,
                    step=1,
                    value=6
                )
                
        ]),
        html_div(className="w3-col l4 m4",
        children = [
            "Number of rows",
            dcc_slider(
                    id="rows",
                    min=1,
                    max=100,
                    step=5,
                    value=20,
                )
        ])
        ]),

    html_p(id = "rc_label"),
    
    
    html_h2("Image collections"),
    html_div(className="w3-panel w3-round w3-border-left w3-border-gray",
        children = [dcc_markdown(
        """*Clear page selection below (if any), then choose an image collection*"""
    )]),
      #=
    dcc_radioitems(
        id = "collection",
        options = collectionmenu(imagecites)
    ),=#
    
    html_div(  
        className = "w3-col l6 m6",        
        children = [
            html_h2("Page"),
            html_div(id = "pagelabel"),
            dcc_dropdown(id = "pg"),
            ]
    ),
    html_div(id = "display")
        
end


# Format an alert-type div displyaing selected rows/columns
callback!(app, 
    Output("rc_label", "children"), 
    Input("columns", "value"),
    Input("rows", "value")
    ) do  c, r
    
    msg = html_div(className="w3-panel w3-round w3-border-left w3-border-gray",
    dcc_markdown("*Format display in tables of **$(c)** columns  × **$(r)** rows of 
    images*.")
    )
    return msg
end


run_server(app, "0.0.0.0", DEFAULT_PORT, debug=true)