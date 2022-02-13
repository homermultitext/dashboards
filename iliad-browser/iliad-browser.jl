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
using HTTP
using CitableBase, CitableObject, CitableImage, CitableText
using CitablePhysicalText
using CitableAnnotations


ILIAD = CtsUrn("urn:cts:greekLit:tlg0012.tlg001:")
iiifservice = IIIFservice(baseiiifurl, iiifroot)

function loadem(url::AbstractString)
    cexsrc = HTTP.get(url).body |> String
    codexlist = fromcex(cexsrc, Codex)
    indexing = fromcex(cexsrc, TextOnPage)
    (codexlist, indexing)
end

(codices, indexes) = loadem(dataurl)



external_stylesheets = ["https://codepen.io/chriddyp/pen/bWLwgP.css"]
app = dash(external_stylesheets=external_stylesheets)

app.layout = html_div() do
    dcc_markdown("*Dashboard version*: **$(DASHBOARD_VERSION)**"),
    html_h1() do 
        dcc_markdown("HMT project: browse manuscripts by *Iliad* line")
    end,


  
    html_h6("Iliad passage?"),
    dcc_markdown("Enter `book.line` (e.g., `1.1`) followed by return."),
    html_div(
        style=Dict("max-width" => "200px"),
        dcc_input(id = "iliad", value = "", type = "text", debounce = true)
    ),


    html_h6(id="results"),
    dcc_radioitems(id = "mspages")

end

function iliadindex(psg::AbstractString, indices::Vector{TextOnPage})
    query = addpassage(ILIAD, psg)
    psglist = []
    for idx in indices
        match = filter(tpl -> urncontains(query, tpl[1]), idx) |> collect
        push!(psglist, match)
    end
    flatlist = psglist |> Iterators.flatten |> collect
    opting = []
    for pr in flatlist
        pgurn = pr[2]
        pgid = objectcomponent(pgurn)
        msid = collectioncomponent(dropversion(pgurn))
        lbl = "Page $(pgid) in manuscript $(msid)"
        push!(opting,
        (label = lbl, value = string(pgurn)))
    end
    
    opting
end

callback!(app, 
    Output("results", "children"), 
    Output("mspages", "options"), 
    
    Input("iliad", "value"),
    ) do iliad_psg
    msg = dcc_markdown("##### Results for $(iliad_psg)")
    optlist = iliadindex(iliad_psg, indexes)
    opts = [
    (label = "Match for $(iliad_psg) goes here", value = "URN goes here")
    ]
    (msg, [(label = "Radios for $(length(optlist)) options", value = "")])
end

run_server(app, "0.0.0.0", debug=true)
