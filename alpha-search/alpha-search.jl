# Run this dashboard from the root of the
# github repository:
using Pkg
if  ! isfile("Manifest.toml")
    Pkg.activate(".")
    Pkg.instantiate()
end

DASHBOARD_VERSION = "0.2.0"

# Variables configuring the app:  
#
#  1. location  of the assets folder (CSS, etc.)
#  2. port to run on
# 
# Set an explicit path to the `assets` folder
# on the assumption that the dashboard will be started
# from the root of the gh repository!
assets = joinpath(pwd(), "alpha-search", "assets")
DEFAULT_PORT = 8050

using Dash
using CitableBase, CitableText, CitableCorpus
using CiteEXchange
using Downloads
using Unicode


# Search on strings of MIN_LENGTH or more chars:
MIN_LENGTH = 3

dataurl = "https://raw.githubusercontent.com/homermultitext/hmt-archive/master/release-candidates/hmt-current.cex"

""" Extract text catalog, normalized editions of texts,
and release info from HMT publication.
"""
function loadhmtdata(url)
    cexsrc = Downloads.download(url) |> read |> String
    textcatalog = fromcex(cexsrc, TextCatalogCollection)
    corpus = fromcex(cexsrc, CitableTextCorpus)

    normalizedtexts = filter(
        psg -> endswith(workcomponent(psg.urn), "normalized"),
        corpus.passages)

    libinfo = blocks(cexsrc, "citelibrary")[1]
    infoparts = split(libinfo.lines[1], "|")    

    (textcatalog, normalizedtexts, infoparts[2])
end

(catalog, normalizededition, releaseinfo) = loadhmtdata(dataurl)

app = if haskey(ENV, "URLBASE")
    dash(assets_folder = assets, url_base_pathname = ENV["URLBASE"])
else 
    dash(assets_folder = assets)    
end

app.layout = html_div() do

    dcc_markdown() do 
        """*Dashboard version*: **$(DASHBOARD_VERSION)**. 
        
        *Data version*: **$(releaseinfo)**
        """
    end,
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

"""Select selection of texts for requested MS."""
function select_texts(psgs, siglum, txt)
    txts_for_ms = if siglum == "all"
		psgs
	elseif siglum == "va"
		msascholia = filter(p -> startswith(workcomponent(p.urn), "tlg5026.msA"), psgs)
		msailiad = filter(p -> startswith(workcomponent(p.urn), "tlg0012.tlg001.msA"), psgs)
		vcat(msascholia, msailiad)
	end

    if txt == "all"
		txts_for_ms
	elseif txt == "iliad"
		iliadurn = CtsUrn("urn:cts:greekLit:tlg0012.tlg001:")
		filter(p -> urncontains(iliadurn, p.urn), txts_for_ms)
	elseif txt == "scholia"
		scholiaurn = CtsUrn("urn:cts:greekLit:tlg5026:")
		filter(p -> urncontains(scholiaurn, p.urn), txts_for_ms)
	end
end


"""Find text passages in `psgs` matching `queryterm`, 
and format markdown display of results.
"""
function displaymarkdown(psgs, queryterm)
    # Find indices for matches in alphabetic version,
    alphabeticstrings = map(psg -> Unicode.normalize(psg.text, stripmark=true) |> lowercase, psgs)
    # use fully formatted version:
    indices = findall(contains(lowercase(queryterm)), alphabeticstrings)
    hits = []
    for i in indices
        push!(hits, psgs[i])
    end
    summary = "## $(length(hits)) matches for **$(queryterm)**\n\n(Searched $(length(psgs)) citable passages.)"
    #summary * "\n\n" * formatpsgs(hits)
    summary * "\n\n" * formatpsgs(hits)

end

function formatpsgs(psglist)
    # Format results in markdown:
    currentwork = nothing
    mdlines = []
    for psg in psglist
        newwork = droppassage(psg.urn)
        if newwork != currentwork
            title = titleforurn(newwork, catalog)
            push!(mdlines, "#### $(title)")
            currentwork = newwork
        end
        push!(mdlines, formatpassage(psg))
    end
    join(mdlines, "\n\n")
end

callback!(
    app, 
    Output("results", "children"), 
    Input("query", "value"),
    Input("ms", "value"),
    Input("txt", "value"),
    ) do query_value, ms_value, txt_value
    
    passages_for_ms = select_texts(normalizededition, ms_value, txt_value)

    if isnothing(passages_for_ms)
        "(no matches)"
    elseif length(query_value) >= MIN_LENGTH
        mdcontent = displaymarkdown(passages_for_ms, query_value)
        dcc_markdown(mdcontent)
        
    else
        "Selected corpus has $(length(passages_for_ms)) passages. "
    end
end

run_server(app, "0.0.0.0", DEFAULT_PORT, debug=true)
