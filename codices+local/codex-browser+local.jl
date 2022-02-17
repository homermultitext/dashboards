# Run this dashboard from the root of the
# github repository:
using Pkg
if  ! isfile("Manifest.toml")
    Pkg.activate(".")
    Pkg.instantiate()
end


DASHBOARD_VERSION = "0.1.0"
# Variables configuring the app:  
#
#  1. location  of the assets folder (CSS, etc.)
#  2. port to run on
# 
# Set an explicit path to the `assets` folder
# on the assumption that the dashboard will be started
# from the root of the gh repository!
assets = joinpath(pwd(), "iliad-browser", "assets")
DEFAULT_PORT = 8054

IMG_HEIGHT = 600

baseiiifurl = "http://www.homermultitext.org/iipsrv"
iiifroot = "/project/homer/pyramidal/deepzoom"

ict = "http://www.homermultitext.org/ict2/?"

dataurl = "https://raw.githubusercontent.com/homermultitext/hmt-archive/master/releases-cex/hmt-current.cex"

using Dash
using CitableBase, CitablePhysicalText, CitableObject
using CitableImage
using FileIO, ImageIO
using Images
using CiteEXchange
using Downloads
using Plots
plotly()

iiifservice = IIIFservice(baseiiifurl, iiifroot)

""" Extract codices and release info from HMT publication.
"""
function loadhmtdata(url)
    cexsrc = Downloads.download(url) |> read |> String
    codexlist = fromcex(cexsrc, Codex)
    libinfo = blocks(cexsrc, "citelibrary")[1]
    infoparts = split(libinfo.lines[1], "|")  
    (codexlist, infoparts[2])
end
(codices, releaseinfo) = loadhmtdata(dataurl)


app =  dash(assets_folder = assets)

app.layout = html_div() do
    dcc_markdown("""
    *Dashboard version*: **$(DASHBOARD_VERSION)**
    
          
    *HMT data version*: **$(releaseinfo)**
    """),
    html_h1() do 
        dcc_markdown("HMT project: simple codex facsimiles"),
        html_h2("With option to use local files")
    end,
   
    dcc_markdown(
        "*Use data from*:"
    ),
    dcc_radioitems(
        id ="datasources",
        options = [
            (label = "HMT release", value = "hmt"),
            (label = "Local data", value = "local")
        ],
        value = "hmt",
        labelStyle = Dict("display" => "inline-block")
    ),

    html_h2(id = "listheader"),
    html_h6("Choose manuscript and page"),
  
    dcc_markdown("*Manuscript*:"),
    dcc_radioitems(
        id = "ms"),

    dcc_markdown("*Page*:"),
    dcc_dropdown(id = "pg"),
    

    html_div(id = "display")
end

# Kludge until bug in Codex constructor losing labelling info (!) is fixed...
function msmenuopts(codd::Vector{Codex})
    opts = []
    for c in codd
        lbl = c.pages[1].urn |> dropversion |> collectioncomponent
        coll = c.pages[1].urn |> dropobject
        push!(opts, (label = "Manuscript $(lbl)", value = string(coll)))
    end
    opts
end


"""Read Codex data from `codices` subdirecteory.
Assume one Codex per file.
"""
function localcodices()
    basedir = joinpath(pwd(), "codices", "codices")
    filenames = readdir(basedir)
    codexlist = Codex[]
    for f in filter(f -> endswith(f, "cex"), filenames)        
        fullpath = joinpath(basedir, f)
        println(fullpath)
        push!(codexlist, fromcex(fullpath, Codex, FileReader)[1])
    end
    codexlist
end

"""Get list of Codex objects from user's choice of source."""
function get_mss_from_src(opt, codexlist)
    if opt == "hmt"
        codexlist
    elseif opt == "local"
        localcodices()
    end
end


"""Find pages for specified manuscript and format option
pairs to use in pages menu.
"""
function pagesmenu(datasrc, ms, codexlist)
    if isnothing(ms)
        []
    else
        mslist = get_mss_from_src(datasrc, codexlist)
        u = Cite2Urn(ms)
        if (isempty(mslist))
            @warn("No MSS from source $(datasrc)")
            return(
                [(label = "No MSS from source $(datasrc)", value = "x")]
            )
        end   

        matches = filter(c -> urn(c) == u, mslist)
        if (isempty(matches))
            return(
                [(label = "$(u) not found in $(mslist)", value = "x")]
            )
        end
        
        opts = []
        for p in matches[1].pages
            lbl = urn(p) |> objectcomponent
            val = string(urn(p))
            push!(opts, (label = lbl, value = val))
        end
        return(opts)
          
    end
end

"""Create menu of manuscripts based on user's choice of source."""
function msmenu(srcchoice, codexlist)
    if srcchoice == "hmt"
        msmenuopts(codexlist)
    elseif srcchoice == "local"
        localmss = localcodices()
        #[(label = "local only: $(localmss) codices", value = "local")]
        msmenuopts(localmss)
    else
        [(label = "BOTH", value = "both")]
    end
end


"""True if `id` is absent from HMT codexlist."""
function islocal(u, hmtcodices)
    id = string(u)
    idlist = map(c -> string(urn(c)), hmtcodices)
    inhmtlist = findall(x -> x == id, idlist)
    isempty(inhmtlist)
end


"""Create plotly graph of local file, scaled to `pct`."""
function graphforfile(f; pct = 0.5)
    pctimg = imresize(load(f), ratio = pct)
    @info("Plotting img for $(f)")
    p = plot(pctimg)
    data = Plots.plotly_series(p)
    data[1][:z] = [c for c in eachcol(data[1][:z])] # <-- As a temporary
    layout = Plots.plotly_layout(p)
    # Fix aspect ratio:
    layout[:height] = size(pctimg)[1]
    layout[:width] = size(pctimg)[2]
    @info("Completed plot: returning dcc_graph object")
    html_div() do
        dcc_markdown("Use the `+`/`-` buttons to zoom in or out, and the crossed arrows to pan."),
        dcc_graph(
                id = "localimage",
                figure = (;data, layout)
            )
    end
end


"""Create HTML facsimile view of specified MS page."""
function facs(datasrc, pg, codexlist)
    mslist = get_mss_from_src(datasrc, codexlist)
    if isnothing(pg)
        nothing
    else
        pgurn = Cite2Urn(pg)
        codexurn = pgurn |> dropobject
        matches  = filter(c -> urn(c) == codexurn, mslist)
        if isempty(matches)
            return("")
        end
        ms = matches[1]
        mspage = filter(p -> urn(p) == pgurn, ms.pages)[1]
        imglink = ""
        if islocal(codexurn, codexlist)
            fname = mspage.image |> objectcomponent
            imgfile = joinpath(pwd(), "codices", "images", fname)
            imglink = graphforfile(imgfile)
           
        else
            lines = ["(The image is linked to a pannable/zoomable view in the HMT Image Citation Tool.)",
            linkedMarkdownImage(ict, mspage.image, iiifservice; ht=IMG_HEIGHT, caption="$(pg)")
            ]
            imglink = join(lines, "\n\n")  |> dcc_markdown
        end

        [
            html_h6("Folio $(objectcomponent(pgurn))"),  
            imglink
        ]
    end
end


callback!(app,
    Output("ms", "options"), 
    Input("datasources", "value"),
    ) do sources
    return msmenu(sources, codices)
end


callback!(app, 
    Output("pg", "options"), 
    Input("datasources", "value"),
    Input("ms", "value"),
    prevent_initial_call=true
    ) do  src, ms_choice
    return pagesmenu(src, ms_choice, codices)
end


callback!(app, 
    Output("display", "children"), 
    Input("pg", "value"),
    Input("datasources", "value"),
    prevent_initial_call=true
    ) do pg_choice, data_src
    return facs(data_src, pg_choice, codices)
end


run_server(app, "0.0.0.0", DEFAULT_PORT, debug=true)
