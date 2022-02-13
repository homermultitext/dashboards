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
using CitableBase, CitableObject, CitableImage
using CitablePhysicalText
using CitableAnnotations



codices = fromcex(dataurl, Codex, UrlReader)
iiifservice = IIIFservice(baseiiifurl, iiifroot)


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


callback!(app, 
    Output("results", "children"), 
    Output("mspages", "options"), 
    
    Input("iliad", "value"),
    ) do iliad_psg
    msg = dcc_markdown("##### Results for $(iliad_psg)")
    #iliadindex(iliad_psg)
    opts = [
    (label = "Match for $(iliad_psg) goes here", value = "URN goes here")
    ]
    (msg, opts)
end

run_server(app, "0.0.0.0", debug=true)
