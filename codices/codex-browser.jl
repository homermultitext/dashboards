# Run this dashboard from the root of the
# github repository:
using Pkg
if  ! isfile("Manifest.toml")
    Pkg.activate(".")
    Pkg.instantiate()
end

url = "https://raw.githubusercontent.com/homermultitext/hmt-archive/master/releases-cex/hmt-current.cex"


using Dash
using CitableBase, CitablePhysicalText, CitableImage

codices = fromcex(url, Codex, UrlReader)

function facs(ms, pg)
    [
        html_h6("Facsimile of $(ms), pg $(pg)")
    ]
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
        options = [
            (label = "Venetus A", value = "msA"),
            (label = "Venetus B", value = "msB"),
            (label = "Escorial, Ω 1.12", value = "e4"),
            (label = "Escorial, Υ 1.1", value = "e3"),
            (label = "British Library, Burney 86", value = "burney86")
        ],
        value = ""
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
    Output("display", "children"), 
    Input("ms", "value"),
    ) do  ms_choice

    return (playpages(ms_choice), nothing)
end


callback!(app, 
    Output("display", "children"), 
    Input("ms", "value"),
    Input("pg", "value")
    ) do  ms_choice, pg_choice

    return facs(ms_choice, pg_choice)
    #return playpages(ms_choice)
end

run_server(app, "0.0.0.0", debug=true)
