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
using Unicode


codices = fromcex(dataurl, Codex, UrlReader)
iiifservice = IIIFservice(baseiiifurl, iiifroot)


external_stylesheets = ["https://codepen.io/chriddyp/pen/bWLwgP.css"]
app = dash(external_stylesheets=external_stylesheets)

app.layout = html_div() do
    html_h1() do 
        dcc_markdown("HMT project: browse by *Iliad* line")
    end,

    html_h6("Instructions"),
    dcc_markdown(
        """- Search for an *Iliad* line
- Choose a page to view
        """
    ),
  
    html_h6("Iliad passage?"),
    html_div(
        style=Dict("max-width" => "200px"),
        children = [
            "book.line (e.g., '1.1')"
            dcc_input(id = "iliad", value = "", type = "text")
        ]
    ),


    html_h6("Results", id="results"),
    dcc_radioitems(id = "mspages")

end

#=

callback!(app, 
    Output("pg", "options"), 
    Output("debug", "children"), 
    Input("iliad", "value"),
    Input("ms", "value"),
    ) do iliad_psg, ms_choice
    msg = "Include $(iliad_psg) in filter on pages"
    return (playpages(ms_choice), msg)
end
=#

callback!(app, 
    Output("mspages", "options"), 
    Input("iliad", "value"),
    ) do iliad_psg
    #iliadindex(iliad_psg)
    [
    (label = "Match goes here", value = "URN goes here")
    ]
end

run_server(app, "0.0.0.0", debug=true)
