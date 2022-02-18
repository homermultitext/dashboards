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
DEFAULT_PORT = 8051

IMG_HEIGHT = 600

baseiiifurl = "http://www.homermultitext.org/iipsrv"
iiifroot = "/project/homer/pyramidal/deepzoom"

ict = "http://www.homermultitext.org/ict2/?"

dataurl = "https://raw.githubusercontent.com/homermultitext/hmt-archive/master/releases-cex/hmt-current.cex"

using Dash
using CitableBase, CitablePhysicalText, CitableObject
using CitableImage
using CiteEXchange
using Downloads

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


# Kludge until bug in Codex constructor losing labelling info (!) is fixed...
function msmenu(codd::Vector{Codex})
    opts = []
    for c in codd
        lbl = c.pages[1].urn |> dropversion |> collectioncomponent
        coll = c.pages[1].urn |> dropobject
        push!(opts, (label = "Manuscript $(lbl)", value = string(coll)))
    end
    opts
end
defaultms = msmenu(codices)[1][2]


"""Create HTML facsimile view of specified MS page."""
function facs(pg)
    if isnothing(pg)
        nothing
    else
        pgurn = Cite2Urn(pg)
        codexurn = pgurn |> dropobject
        ms  = filter(c -> urn(c) == codexurn, codices)[1]
        mspage = filter(p -> urn(p) == pgurn, ms.pages)[1]

        [
            html_h6("Folio $(objectcomponent(pgurn))"),  

            html_p(
                "(The image is linked to a pannable/zoomable view in the HMT Image Citation Tool.)"),
 
            dcc_markdown(
                linkedMarkdownImage(ict, mspage.image, iiifservice; ht=IMG_HEIGHT, caption="$(pg)")
            )
       
        ]
    end
end

"""Find pages for specified manuscript and format option
pairs to use in pages menu.
"""
function pagesmenu(ms::AbstractString)
    u = Cite2Urn(ms)
   
    codex = filter(c -> urn(c) == u, codices)[1]
    opts = []
    for p in codex.pages
        lbl = urn(p) |> objectcomponent
        val = string(urn(p))
        push!(opts, (label = lbl, value = val))
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
        dcc_markdown("HMT project: simple codex facsimiles")
    end,
    html_p("Browse images of $(length(codices)) manuscripts"),

    html_h6("Instructions"),
    dcc_markdown(
        """- Choose a manuscript and page to view
        """
    ),
  
    html_h6("Manuscript"),
    dcc_radioitems(
        id = "ms",
        options = msmenu(codices),
        value = defaultms
    ),

    html_div() do
        html_h6("Page"),
        dcc_dropdown(id = "pg")
    end,

    html_div(id = "display")
end

callback!(app, 
    Output("pg", "options"), 
    Input("ms", "value"),
    ) do  ms_choice
    return pagesmenu(ms_choice)
end


callback!(app, 
    Output("display", "children"), 
    Input("pg", "value")
    ) do pg_choice
    return facs(pg_choice)
end

run_server(app, "0.0.0.0", DEFAULT_PORT, debug=true)
