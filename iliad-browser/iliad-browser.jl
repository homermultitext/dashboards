# Run this dashboard from the root of the
# github repository:
using Pkg
if  ! isfile("Manifest.toml")
    Pkg.activate(".")
    Pkg.instantiate()
end


DASHBOARD_VERSION = "0.1.0"
DEFAULT_PORT = 8054

IMG_HEIGHT = 1000
baseiiifurl = "http://www.homermultitext.org/iipsrv"
iiifroot = "/project/homer/pyramidal/deepzoom"
ict = "http://www.homermultitext.org/ict2/?"

dataurl = "https://raw.githubusercontent.com/homermultitext/hmt-archive/master/releases-cex/hmt-current.cex"


using Dash
using HTTP
using CitableBase, CitableObject, CitableImage, CitableText
using CitablePhysicalText
using CitableAnnotations
using CiteEXchange

ILIAD = CtsUrn("urn:cts:greekLit:tlg0012.tlg001:")
iiifservice = IIIFservice(baseiiifurl, iiifroot)

function loadhmtdata(url::AbstractString)
    cexsrc = HTTP.get(url).body |> String
    codexlist = fromcex(cexsrc, Codex)
    indexing = fromcex(cexsrc, TextOnPage)
    libinfo = blocks(cexsrc, "citelibrary")[1]
    infoparts = split(libinfo.lines[1], "|")
    (codexlist, indexing, infoparts[2])
end

(codices, indexes, releaseinfo) = loadhmtdata(dataurl)



external_stylesheets = ["https://codepen.io/chriddyp/pen/bWLwgP.css"]
app = dash(external_stylesheets=external_stylesheets)

#assetfolder = joinpath(pwd(), "dashboard", "assets")
#app = dash(assets_folder = assetfolder, include_assets_files=true)


app.layout = html_div() do
    dcc_markdown() do 
        """*Dashboard version*: **$(DASHBOARD_VERSION)**. 
        
        *Data version*: **$(releaseinfo)**
        """
    end,
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
    dcc_radioitems(id = "mspages"),
    html_div(id="pagedisplay")
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


function pagemarkdown(pg::AbstractString, codexlist::Vector{Codex}; ict, service, height)
    pgurn = Cite2Urn(pg)
    msid = dropversion(pgurn) |> collectioncomponent
    pgid = objectcomponent(pgurn)

    mspage = nothing
    for c in codexlist
        for pgrecord in filter(p -> urn(p) == pgurn, c)
            mspage = pgrecord
        end
    end

    hdr = "##### Page $(pgid) in MS $(msid)"
    nb = "Image is linked to a zoomable/pannable view in the HMT Image Citation Tool."
    para = isnothing(mspage) ? "No model for $(pg) found" : linkedMarkdownImage(ict, mspage.image, service; ht=height, caption="$(label(mspage))")
    join([hdr, nb, para], "\n\n")
end

callback!(app, 
    Output("results", "children"), 
    Output("mspages", "options"), 
    
    Input("iliad", "value"),
    prevent_initial_call=true
    ) do iliad_psg
    hdg = dcc_markdown("##### Pages including *Iliad* $(iliad_psg)")
    optlist = iliadindex(iliad_psg, indexes)
   (hdg, optlist)
end

callback!(app, 
    Output("pagedisplay", "children"), 
    Input("mspages", "value"),
    
    prevent_initial_call=true
    ) do pgref
  
    md = pagemarkdown(pgref, codices, ict = ict, service = iiifservice, height = IMG_HEIGHT)
    dcc_markdown(md)
end


run_server(app, "0.0.0.0", DEFAULT_PORT, debug=true)
