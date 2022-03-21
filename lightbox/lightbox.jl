# Run this dashboard from the root of the
# github repository:
using Pkg
Pkg.activate(joinpath(pwd(), "lightbox"))
Pkg.instantiate()

DASHBOARD_VERSION = "0.2.3"
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


baseiiifurl = "http://www.homermultitext.org/iipsrv"
iiifroot = "/project/homer/pyramidal/deepzoom"

ict = "http://www.homermultitext.org/ict2/?"

dataurl = "https://raw.githubusercontent.com/homermultitext/hmt-archive/master/releases-cex/hmt-current.cex"

using Dash
using CitableBase
using CitableObject
using CitableObject.CexUtils
using CitableImage
using CiteEXchange
using Downloads
using Tables

iiifservice = IIIFservice(baseiiifurl, iiifroot)

"""Construct a table of image collections, and release info.
"""
function loadhmtdata(url)
    cexsrc = Downloads.download(url) |> read |> String
    cites = citeids(cexsrc, CitableImage.IMAGE_MODEL)
    imgcollurns = implementations(cexsrc, CitableImage.IMAGE_MODEL)
    newblocks = map(u ->  "#!citedata\n" * join(collectiondata(cexsrc, u), "\n"), imgcollurns)
    imgs = []
    menupairs = []
    for i in 1:length(imgcollurns)
        if length(blocks(newblocks[i])[1].lines) < 5
            @warn("< 5 data lines for $(imgcollurns[i]) ")
        else
            collurn = imgcollurns[i]
            coll =  fromcex(newblocks[i], ImageCollection, strict = false)
            push!(imgs, (urn = string(collurn), images = coll))
            push!(menupairs, cites[i])
        end
    end

    libinfo = blocks(cexsrc, "citelibrary")[1]
    infoparts = split(libinfo.lines[1], "|")  
    (Tables.columntable(imgs), menupairs, infoparts[2])
end
(imagecollections, imagecites, releaseinfo) = loadhmtdata(dataurl)

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

app.layout = html_div() do
    dcc_markdown("""
    *Dashboard version*: **$(DASHBOARD_VERSION)** ([version notes](https://homermultitext.github.io/dashboards/lightbox/))
           
    *Data version*: **$(releaseinfo)**
    """),
    html_h1() do 
        dcc_markdown("HMT project: browse image collections")
    end,
    dcc_markdown("""Browse tables of **$(length(imagecollections.images))** image collections 
    cataloging a total of **$(length.(imagecollections.images) |> sum)** images
    """),

    
    html_div(
        className = "panel",
        children = [
            html_div(
                className = "columnl",
                children = [
                    html_h4("Image collections"),
                    dcc_markdown(
                        """*Clear page selection below (if any), then choose an image collection*"""
                    ),
                    dcc_radioitems(
                        id = "collection",
                        options = collectionmenu(imagecites)
                    )
                ]
            ),

            html_div(
            className = "columnr",
            children = [
            html_h6("Format table"),
            html_p(id = "rc_label"),
        
            dcc_markdown("*Columns*:"),
            dcc_slider(
                id="columns",
                min=4,
                max=10,
                step=1,
                value=6,
            ),

            dcc_markdown("*Rows*:"),
            dcc_slider(
                id="rows",
                min=0,
                max=100,
                step=5,
                value=20,
            ),
            ]
        ),
        ]
    ),


    html_div(
    className = "panel",

    children = [
        

        html_div(
            className = "columnl",            
            children = [
                html_h6("Page"),
                html_div(id = "pagelabel"),
                dcc_dropdown(id = "pg"),
                ]
        )
    ]),

    html_div(id = "display")

end


callback!(app, 
    Output("rc_label", "children"), 
    Input("columns", "value"),
    Input("rows", "value")
    ) do  c, r
    return dcc_markdown("Format display in tables of *$(c)* columns  × *$(r)* rows of images.")
end

callback!(app, 
    Output("pagelabel", "children"), 
    Output("pg", "options"), 
    Input("columns", "value"),
    Input("rows", "value"),
    Input("collection", "value")
    ) do  c, r, coll

    if isnothing(coll)
        ("",[])
    else
        selectedimages = nothing
        for row in Tables.rows(imagecollections)
            if string(row.urn) == string(coll)
                selectedimages = row.images
            end
        end
       
        if isnothing(selectedimages)
            @warn("No images found for $(coll)")
            ("",[])
        else
            # Somehow I've got this backwards?
            lb = lightbox(selectedimages[1], cols = r, rows = c)
            lbl = """
             *Choose a lightbox table from $(pages(lb)) pages for $(coll)* ($(selectedimages |> length) images in $(c) ×  $(r) tables)
            """
           #lbl = "HELP. $(lb) from $(coll)"

            optlist = []
            for pnum in 1:pages(lb)
                push!(optlist, (label = "Page $(pnum)", value = pnum))
            end

            (dcc_markdown(lbl), optlist)
        end
    end
end

callback!(app, 
    Output("display", "children"), 
    Input("pg", "value"),
    State("collection", "value"),
    State("columns", "value"),
    State("rows", "value")
    ) do  pg, coll, r, c
    if isnothing(pg)
        ""
    else
        selectedimages = nothing
        for row in Tables.rows(imagecollections)
            if row.urn == coll
                selectedimages = row.images
            end
        end
        
        #@info("Checking $coll")
        #@info("Found ", selectedimages)
        if isnothing(selectedimages)
            @warn("No images matched for $(coll)")
            ""
        else
            lb = lightbox(selectedimages[1], cols = r, rows = c)
            preface = "#### Page $(pg)\n\nThumbnail images are linked to pannable/zoomable images in the HMT Image Citation Tool.\n\n"
            dcc_markdown(preface * mdtable(lb, pg))
        end
    end
end


run_server(app, "0.0.0.0", DEFAULT_PORT, debug=true)
