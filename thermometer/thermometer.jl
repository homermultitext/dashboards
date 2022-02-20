# CHECK OUT PLOTTING HERE:
# https://dash.plotly.com/julia/interactive-graphing

#
# Run this dashboard from the root of the
# github repository:
using Pkg
if  ! isfile("Manifest.toml")
    Pkg.activate(".")
    Pkg.instantiate(    )
end
DASHBOARD_VERSION = "0.1.0"

# Variables configuring the app:  
#
#  1. location  of the assets folder (CSS, etc.)
#  2. port to run on
# 
# Set an explicit path to the `assets` folder
# on the assumption that the dashboard will be started
# from the root of the gh repository!
assets = joinpath(pwd(), "thermometer", "assets")
DEFAULT_PORT = 8060

dataurl = "https://raw.githubusercontent.com/homermultitext/hmt-archive/master/releases-cex/hmt-current.cex"


using Dash
using CitableBase, CitableText, CitableCorpus
using CitablePhysicalText
using CitableAnnotations
using CiteEXchange
using Downloads
using Unicode
using SplitApplyCombine
using Tables
using PlotlyJS

""" Extract text catalog, normalized editions of texts,
and release info from HMT publication.
"""
function loadhmtdata(url)
    cexsrc = Downloads.download(url) |> read |> String
    mss = fromcex(cexsrc, Codex)
    indexing = fromcex(cexsrc, TextOnPage)
    ctscatalog = fromcex(cexsrc, TextCatalogCollection)
    corpus = fromcex(cexsrc, CitableTextCorpus)

    normalizedtexts = filter(
        psg -> endswith(workcomponent(psg.urn), "normalized"),
        corpus.passages)

    libinfo = blocks(cexsrc, "citelibrary")[1]
    infoparts = split(libinfo.lines[1], "|")    

    (mss, indexing, ctscatalog, normalizedtexts, infoparts[2])
end

(codices, indexes, textcatalog, normalizededition, releaseinfo) = loadhmtdata(dataurl)


"""Format title of a text catalog entry in markdown."""
function format_title(txt)
    #txt.group * ", *", txt.work * "* (", txt.version, ")"
    string(txt)
end

"""Format catalog entries as markdown list"""
function textlist(textcatalog)
    lines = []
    for txt in textcatalog
        push!(lines, "- " * format_title(txt))
    end
    join(lines, "\n")
end

function indexgraph(indices)
    data = []
    for idx in indexes
        for pr in idx.data
            txt = pr[1]
            bk = collapsePassageBy(txt, 1) |> passagecomponent
            pieces = split(workcomponent(txt), ".")
            push!(data, (pieces[end], bk))
        end
    end

    grp = group(data)
    counts = []
    grp = group(data)
    counts = []
    for k in keys(grp)
        push!(counts, (ms = k[1], bk = k[2], count = length(grp[k])))
    end


    mss = map(trpl -> trpl[1], counts) |> unique
    bks = collect(1:24) .|> string

    dataseries = Dict()
    for ms in mss   
        padded = []
        for bk in bks
            extract = filter(trp -> trp[1] == ms && trp[2] == bk, counts)
            isempty(extract) ? push!(padded, (ms = ms,bk = bk,count = 0)) : push!(padded, extract[1])
        end
        dataseries[ms] = Tables.columntable(padded)
    end

    barlist = GenericTrace{Dict{Symbol, Any}}[]
    for k in keys(dataseries)
        tbl = dataseries[k]
        push!(barlist, bar(name=k, x=tbl.bk, y=tbl.count))
    end
    Plot(barlist)
end

app = if haskey(ENV, "URLBASE")
    dash(assets_folder = assets, url_base_pathname = ENV["URLBASE"])
else 
    dash(assets_folder = assets)    
end

app.layout = html_div() do
    html_h1("$(releaseinfo): overview of contents"),
    dcc_markdown("""
    
    """),
    html_h2("Images"),
    "TBA",
    html_h2("Manuscripts"),
    dcc_markdown("""
    **$(length(codices))** cataloged manuscripts


    Explore manuscripts with the [codex-browser dashboard](https://www.homermultitext.org/codex-browser/).


    ### Quire marks

    (TBA)
    """),
    html_h2("Indexes to manuscripts"),
    indexgraph(indexes),
    dcc_markdown("""
    
    Explore indexed manuscripts with the [iliad-browser dashboard](https://www.homermultitext.org/iliad-browser/).
    """),
    html_h2("Editing"),
    dcc_markdown("""
    $(length(textcatalog)) texts.


    $(textlist(textcatalog))
    
    Explore edited texts with the [alpha-search dashboard](https://www.homermultitext.org/alpha-search/).
    """),

    dcc_markdown("""
### Contents of texts

#### Named figures

(TBA)

#### Named places

(TBA)

#### Peoples and ethnic groups

(TBA)

#### The Venetus A manuscript


##### Critical signs

(TBA)


    """)
end

run_server(app, "0.0.0.0", DEFAULT_PORT, debug=true)


#=


data = []
for idx in indexes
    for pr in idx.data
        txt = pr[1]
        bk = collapsePassageBy(txt, 1) |> passagecomponent
        pieces = split(workcomponent(txt), ".")
        push!(data, (pieces[end], bk))
    end
end

grp = group(data)
counts = []
grp = group(data)
counts = []
for k in keys(grp)
	push!(counts, (ms = k[1], bk = k[2], count = length(grp[k])))
end


mss = map(trpl -> trpl[1], counts) |> unique
bks = collect(1:24) .|> string

dataseries = Dict()
for ms in mss   
    padded = []
    for bk in bks
        extract = filter(trp -> trp[1] == ms && trp[2] == bk, counts)
        isempty(extract) ? push!(padded, (ms = ms,bk = bk,count = 0)) : push!(padded, extract[1])
    end
    dataseries[ms] = Tables.columntable(padded)
end

barlist = GenericTrace{Dict{Symbol, Any}}[]
for k in keys(dataseries)
    tbl = dataseries[k]
    push!(barlist, bar(name=k, x=tbl.bk, y=tbl.count))
end
plot(barlist)
=#