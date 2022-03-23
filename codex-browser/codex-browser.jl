# Run this dashboard from the root of the
# github repository:
using Pkg
Pkg.activate(joinpath(pwd(), "codex-browser"))
Pkg.resolve()
Pkg.instantiate()


DASHBOARD_VERSION = "0.2.6"
# Variables configuring the app:  
#
#  1. location  of the assets folder (CSS, etc.)
#  2. port to run on
# 
# Set an explicit path to the `assets` folder
# on the assumption that the dashboard will be started
# from the root of the gh repository!
assets = joinpath(pwd(), "codex-browser", "assets")
DEFAULT_PORT = 8051

IMG_HEIGHT = 600

using Dash
using CitableBase, CitablePhysicalText, CitableObject
using CitableImage
using HmtArchive, HmtArchive.Analysis
using CiteEXchange
using Downloads

baseiiifurl = "http://www.homermultitext.org/iipsrv"
iiifroot = "/project/homer/pyramidal/deepzoom"
ict = "http://www.homermultitext.org/ict2/?"
iiifservice = IIIFservice(baseiiifurl, iiifroot)

""" Extract codices and release info from HMT publication.
"""
function loadhmtdata()
    src = hmt_cex()
    codexlist = hmt_codices(src)
    (codexlist, hmt_releaseinfo(src))
end
(codices, releaseinfo) = loadhmtdata()


"""Create menu options for list of codices."""
function msmenu(codd::Vector{Codex})
    opts = []
    for c in codd
        push!(opts, (label = "$(label(c))", value = string(urn(c))))
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
                "The image is linked to a pannable/zoomable view in the HMT Image Citation Tool."),
 
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

app.layout = html_div(className = "w3-container") do
    html_div(className = "w3-container w3-light-gray w3-cell w3-mobile w3-border-left w3-border-gray",
    children = [dcc_markdown("*Dashboard version*: **$(DASHBOARD_VERSION)** ([version notes](https://homermultitext.github.io/dashboards/codex-browser/))")]),

    html_div(className = "w3-container w3-light-gray w3-cell w3-mobile w3-border-left w3-border-gray",
    children = [dcc_markdown("*Data version*: **$(releaseinfo)** ([source](https://raw.githubusercontent.com/homermultitext/hmt-archive/master/releases-cex/hmt-current.cex))")]),





    html_h1() do 
        dcc_markdown("HMT project: simple codex facsimiles")
    end,
    dcc_markdown("""### Browse images of **$(length(codices))** manuscripts

    """),


    html_div(className = "w3-panel w3-round  w3-border-left w3-border-gray",
    dcc_markdown("*Clear the page selection (if any), and choose a manuscript*.")
    ),

    html_div( 
        className = "w3-container",
        children = [


            html_div(
                className = "w3-col l4 m4 s12",
                children = [
                dcc_markdown("*Choose a manuscript*"),
                dcc_dropdown(
                    id = "ms",
                    options = msmenu(codices),
                    value = defaultms
                )
                ]
            ),

            html_div(
                className = "w3-col l4 m4 s12",
                children = [
                    dcc_markdown("*Choose a page*"),
                    dcc_dropdown(id = "pg")
                ]
            ),
        ]
    ),

    dcc_markdown("## Display page"),
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
