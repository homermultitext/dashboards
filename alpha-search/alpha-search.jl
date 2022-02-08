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

MIN_LENGTH = 3

url = "https://raw.githubusercontent.com/homermultitext/hmt-archive/master/release-candidates/hmt-current.cex"


catalog = fromcex(url, TextCatalogCollection, UrlReader)
normalizededition = filter(psg -> endswith(workcomponent(psg.urn), "normalized"),
    fromcex(url, CitableTextCorpus, UrlReader).passages)

external_stylesheets = ["https://codepen.io/chriddyp/pen/bWLwgP.css"]
app = dash(external_stylesheets=external_stylesheets)


app.layout = html_div() do
    html_h1("HMT project: search corpus by alphabetic string"),
    html_blockquote() do
        html_ul() do
            html_li("Select manuscripts and texts to include"),
            html_li("Enter an alphabetic string (no accents or breathings) in Unicode Greek to search for"),
            html_li() do
                dcc_markdown("Minimum length of query string is **3 characters**")
            end
        end
    end,
    html_div() do
            "Manuscripts to include:",
            html_div(style=Dict("max-width" => "200px"),
                dcc_dropdown(
                    id = "ms",
                    options = [
                        (label = "All manuscripts", value = "all"),
                        (label = "Venetus A", value = "va")
                    ],
                    value = "all",
                    clearable=false
                )
            )
    end,
    html_div() do
        "Texts to include:",
        html_div(style=Dict("max-width" => "200px"),
            dcc_dropdown(
                id = "txt",
                options = [
                    (label = "All texts", value = "all"),
                    (label = "Iliad", value = "iliad"),
                    (label = "scholia", value = "scholia"),
                ],
                value = "scholia",
                clearable=false
            )
        )
    end,
  
    html_div(
        children = [
        "Search for: ",
        dcc_input(id = "query", value = "", type = "text")
        ]
    ),
    html_br(),
    html_div(id = "results")
end

"Format a citable passage in markdown."
function formatpassage(psg)
	"1. **" * passagecomponent(psg.urn) * "**: " * psg.text
end

"Format the title of a cataloged work in markdown."
function markdowntitle(catentry::CatalogedText)
	if isiliad(urn(catentry))
		textgroup(catentry) * ", *" * work(catentry) * "* (" * version(catentry) * ")"
	else
		textgroup(catentry) * ", *" * work(catentry) * "*"
	end
end


"Look up formatted title for text `u` in a text catalog."
function titleforurn(u::CtsUrn, catalog::TextCatalogCollection)
	catalogurn = isiliad(u) ? dropexemplar(u) : dropversion(u)
	
	catentries = urncontains(catalogurn, catalog).entries
	if length(catentries) == 1
		markdowntitle(catentries[1])
	else
		"FAILED TO FIND $(u)  in catalog"
	end
end

"True if `u` identifies an `Iliad` passage."
function isiliad(u::CtsUrn)
	urncontains(CtsUrn("urn:cts:greekLit:tlg0012.tlg001:"), u)
end

callback!(app, 
    Output("results", "children"), 
    Input("query", "value"),
    Input("ms", "value"),
    Input("txt", "value"),
    ) do query_value, ms_value, txt_value


    selected_mss = if ms_value == "all"
		normalizededition
	elseif ms_value == "va"
		msascholia = filter(p -> startswith(workcomponent(p.urn), "tlg5026.msA"), normalizededition)
		msailiad = filter(p -> startswith(workcomponent(p.urn), "tlg0012.tlg001.msA"), normalizededition)
		vcat(msascholia, msailiad)
	end
    
    selected_passages = if txt_value == "all"
		selected_mss
	elseif txt_value == "iliad"
		iliadurn = CtsUrn("urn:cts:greekLit:tlg0012.tlg001:")
		filter(p -> urncontains(iliadurn, p.urn), selected_mss)
	elseif txt_value == "scholia"
		scholiaurn = CtsUrn("urn:cts:greekLit:tlg5026:")
		filter(p -> urncontains(scholiaurn, p.urn), selected_mss)
	end
   
    if isnothing(selected_passages)
        ""
    elseif length(query_value) > 2
        # Find indices for matches in alphabetic version,
        # use fully formatted version:
        alphabeticstrings = map(psg -> Unicode.normalize(psg.text, stripmark=true) |> lowercase, selected_passages)
        indices = findall(contains(lowercase(query_value)), alphabeticstrings)
        hits = []
		for i in indices
			push!(hits, selected_passages[i])
		end
        summary = "## $(length(hits)) matches for **$(query_value)**\n\n$(length(selected_passages)) citable passages in $(ms_value)."

        # Format results in markdown:
        currentwork = nothing
		mdlines = [summary]
		for psg in hits
			newwork = droppassage(psg.urn)
			if newwork != currentwork
				title = titleforurn(newwork, catalog)
				push!(mdlines, "#### $(title)")
				currentwork = newwork
			end
			push!(mdlines, formatpassage(psg))
		end
		mdcontent = join(mdlines, "\n\n")
        dcc_markdown(mdcontent)
      
    else
        "Selected corpus has $(length(selected_passages)) passages. "

    end
end

run_server(app, "0.0.0.0", debug=true)
