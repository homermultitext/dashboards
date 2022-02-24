# Run this dashboard from the root of the
# github repository:
using Pkg
Pkg.activate(joinpath(pwd(), "lightbox"))
Pkg.instantiate()

DASHBOARD_VERSION = "0.1.0"
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

    imgcollurns = implementations(cexsrc, CitableImage.IMAGE_MODEL)
    newblocks = map(u ->  "#!citedata\n" * join(collectiondata(cexsrc, u), "\n"), imgcollurns)
    #sigla  = map(u -> u |> dropversion |> collectioncomponent, imgcollurns)
    # 
    imgs = []
    #for i in 1:length(sigla)
    for i in 1:length(imgcollurns)
        if length(blocks(newblocks[i])[1].lines) < 5
            @warn("< 5 data lines for $(imgcollurns[i]) ")
        else
            collurn = imgcollurns[i]
            siglum = dropversion(collurn) |> collectioncomponent
            coll =  fromcex(newblocks[i], ImageCollection, strict = false)
            push!(imgs, (urn = collurn, siglum = siglum, images = coll))
        end
    end

    libinfo = blocks(cexsrc, "citelibrary")[1]
    infoparts = split(libinfo.lines[1], "|")  
    (Tables.columntable(imgs), infoparts[2])
end
(imagecollections, releaseinfo) = loadhmtdata(dataurl)

"""Compose radio options for selecting image collection."""
function collectionmenu(imgcolls)#codd::Vector{Codex})
    opts = []
    for sig in imgcolls.siglum
        push!(opts, (label = sig, value = sig))
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
    *Dashboard version*: **$(DASHBOARD_VERSION)**
           
    *Data version*: **$(releaseinfo)**
    """),
    html_h1() do 
        dcc_markdown("HMT project: browse image collections")
    end,
    dcc_markdown("""Browse tables of **$(length(imagecollections.images))** image collections 
    cataloging a total of **$(length.(imagecollections.images) |> sum)** images
    """),

    
  
    html_h6("Image collections"),
    dcc_markdown(
        """*Choose an image collection*"""
    ),
    dcc_radioitems(
        id = "collection",
        options = collectionmenu(imagecollections)
    ),
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

    html_h6("Page"),

    html_div(id = "pagelabel"),
    dcc_dropdown(id = "pg"),
    

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
    Input("collection", "value"),
    Input("columns", "value"),
    Input("rows", "value")
    ) do  coll, c, r

    if isnothing(coll)
        ""
    else
        selectedimages = nothing
        for row in Tables.rows(imagecollections)
            if row.siglum == coll
                selectedimages = row.images
            end
        end
       
        # Somehow I've got this backwards?
        lb = lightbox(selectedimages, cols = r, rows = c)
        lbl = """Thumbnail images are linked to pannable/zoomable images in the HMT Image Citation Tool.
        
        *Choose a lightbox table from $(pages(lb)) pages for $(coll)* ($(selectedimages |> length) images in $(c) ×  $(r) tables)
        """

        optlist = []
        for pnum in 1:pages(lb)
            push!(optlist, (label = "Page $(pnum)", value = pnum))
        end

        (dcc_markdown(lbl), optlist)
    end
end

callback!(app, 
    Output("display", "children"), 
    Input("pg", "value"),
    State("collection", "value"),
    State("columns", "value"),
    State("rows", "value")
    ) do  pg, coll, r, c
    selectedimages = nothing
    for row in Tables.rows(imagecollections)
        if row.siglum == coll
            selectedimages = row.images
        end
    end
    
    lb = lightbox(selectedimages, cols = r, rows = c)
    dcc_markdown(mdtable(lb, pg))
end


run_server(app, "0.0.0.0", DEFAULT_PORT, debug=true)
