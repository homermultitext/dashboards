# Run this dashboard from the root of the
# github repository:
using Pkg
if  ! isfile("Manifest.toml")
    Pkg.activate(".")
    Pkg.instantiate()
end

url = "https://raw.githubusercontent.com/homermultitext/hmt-archive/master/releases-cex/hmt-current.cex"


using Dash
using CitableBase, CitablePhysicalText, CitableObject
using CitableImage

codices = fromcex(url, Codex, UrlReader)


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
        [
            html_h6("Facsimile of $(pg)")
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

function playpages(siglum)
    if siglum == "msA"
        [(label = "12 recto", value = "12r"),
        (label = "12 verso", value = "12v")]
    else
        [(label = "1 recto", value = "1r"),
        (label = "1 verso", value = "1v")]
    end
end


external_stylesheets = ["https://codepen.io/chriddyp/pen/bWLwgP.css"]
app = dash(external_stylesheets=external_stylesheets)

app.layout = html_div() do
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
