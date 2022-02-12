# Run this dashboard from the root of the
# github repository:
using Pkg
if  ! isfile("Manifest.toml")
    Pkg.activate(".")
    Pkg.instantiate()
end

DASHBOARD_VERSION = "0.1.0"

IMG_HEIGHT = 600

baseiiifurl = "http://www.homermultitext.org/iipsrv"
iiifroot = "/project/homer/pyramidal/deepzoom"

ict = "http://www.homermultitext.org/ict2/?"

dataurl = "https://raw.githubusercontent.com/homermultitext/hmt-archive/master/releases-cex/hmt-current.cex"

using Dash
using CitableBase, CitablePhysicalText, CitableObject
using CitableImage

codices = fromcex(dataurl, Codex, UrlReader)
iiifservice = IIIFservice(baseiiifurl, iiifroot)

# Kludge until proper fix in Codex constructor...
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

external_stylesheets = ["https://codepen.io/chriddyp/pen/bWLwgP.css"]
app = dash(external_stylesheets=external_stylesheets)

app.layout = html_div() do
    dcc_markdown("*Dashboard version*: **$(DASHBOARD_VERSION)**"),
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

    html_div(id = "display"),
    html_div(id = "debug") 


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
    #return playpages(ms_choice)
end

run_server(app, "0.0.0.0", debug=true)
