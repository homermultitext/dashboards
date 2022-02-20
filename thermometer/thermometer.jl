# CHECK OUT PLOTTING HERE:
# https://dash.plotly.com/julia/interactive-graphing

#
# Run this dashboard from the root of the
# github repository:
using Pkg
if  ! isfile("Manifest.toml")
    Pkg.activate(".")
    Pkg.instantiate()
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
DEFAULT_PORT = 8059

dataurl = "https://raw.githubusercontent.com/homermultitext/hmt-archive/master/releases-cex/hmt-current.cex"


using Dash
using CitableBase, CitableText, CitableCorpus
using CiteEXchange
using Downloads
using Unicode
using Plots

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
    html_h1("Homer Multitext archive: overview")
end

run_server(app, "0.0.0.0", DEFAULT_PORT, debug=true)


#=
url = "https://raw.githubusercontent.com/homermultitext/hmt-archive/master/releases-cex/hmt-current.cex"

using CitableBase, CitableObject, CitableImage, CitableText
using CitablePhysicalText
using CitableAnnotations
using CiteEXchange
using Downloads


function loadhmtdata(url::AbstractString)
    cexfile = Downloads.download(url)
    cexsrc = read(cexfile) |> String
    codexlist = fromcex(cexsrc, Codex)
    indexing = fromcex(cexsrc, TextOnPage)
    libinfo = blocks(cexsrc, "citelibrary")[1]
    infoparts = split(libinfo.lines[1], "|")
    (codexlist, indexing, infoparts[2])
end

dataurl = "https://raw.githubusercontent.com/homermultitext/hmt-archive/master/releases-cex/hmt-current.cex"
(codices, indexes, releaseinfo) = loadhmtdata(dataurl)

data = []
for idx in indexes
    for pr in idx.data
        txt = pr[1]
        bk = collapsePassageBy(txt, 1) |> passagecomponent
        pieces = split(workcomponent(txt), ".")
        push!(data, (pieces[end], bk))
    end
end

using SplitApplyCombine
grp = group(data)

counts = []
grp = group(data)
counts = []
for k in keys(grp)
	push!(counts, (ms = k[1], bk = k[2], count = length(grp[k])))
end

mss = map(trpl -> trpl[1], counts) |> unique

dataseries = Dict()
for ms in mss

end

=#