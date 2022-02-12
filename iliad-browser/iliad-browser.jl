# Run this dashboard from the root of the
# github repository:
using Pkg
if  ! isfile("Manifest.toml")
    Pkg.activate(".")
    Pkg.instantiate()
end


using Dash
using CitableBase, CitableText, CitableCorpus
using Unicode

function playpages(siglum)
    if siglum == "msA"
        [(label = "12 recto", value = "12r"),
        (label = "12 verso", value = "12v")]
    else
        [(label = "1 recto", value = "1r"),
        (label = "1 verso", value = "1v")]
    end
end

function iliadindex(psg)
    if psg == "2.600"
        return [
            (label = "Venetus A", value = "msA"),
            (label = "Venetus B", value = "msB"),
            (label = "Escorial, Ω 1.12", value = "e4"),
            (label = "Escorial, Υ 1.1", value = "e3")
        ]
    else
        return [
            (label = "Venetus A", value = "msA"),
            (label = "Venetus B", value = "msB"),
            (label = "Escorial, Ω 1.12", value = "e4"),
            (label = "Escorial, Υ 1.1", value = "e3"),
            (label = "British Library, Burney 86", value = "burney86")
        ]
    end
end

external_stylesheets = ["https://codepen.io/chriddyp/pen/bWLwgP.css"]
app = dash(external_stylesheets=external_stylesheets)

app.layout = html_div() do
    html_h1() do 
        dcc_markdown("HMT project: browse by *Iliad* line")
    end,

    html_h6("Instructions"),
    dcc_markdown(
        """- (Optional) Filter the manuscript selection by *Iliad* line
- Choose a manuscript and page to view
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


    html_div(id = "debug") 


end

callback!(app, 
    Output("pg", "options"), 
    Output("debug", "children"), 
    Input("iliad", "value"),
    Input("ms", "value"),
    ) do iliad_psg, ms_choice
    msg = "Include $(iliad_psg) in filter on pages"
    return (playpages(ms_choice), msg)
end

#=
callback!(app, 
    Output("ms", "options"), 
    Input("iliad", "value"),
    ) do iliad_psg
    optlist = iliadindex(iliad_psg)
    return optlist
end
=#
run_server(app, "0.0.0.0", debug=true)
