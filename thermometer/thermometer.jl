# Run this dashboard from the root of the
# github repository:
using Pkg
Pkg.activate(joinpath(pwd(), "thermometer"))
Pkg.instantiate()

DASHBOARD_VERSION = "0.3.0"

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

using CitableAnnotations
using CitableBase
using CitableCorpus
using CitableImage
using CitableObject
using CitablePhysicalText
using CitableText
using CiteEXchange

using Downloads
using SplitApplyCombine
using Tables
using PlotlyJS

""" Extract text catalog, normalized editions of texts,
and release info from HMT publication.
"""
function loadhmtdata(url)
    cexsrc = Downloads.download(url) |> read |> String
    allimgs = fromcex(cexsrc, ImageCollection)
    imgs = filter(c -> length(c) > 2, allimgs)
    mss = fromcex(cexsrc, Codex)
    indexing = fromcex(cexsrc, TextOnPage)
    ctscatalog = fromcex(cexsrc, TextCatalogCollection)
    corpus = fromcex(cexsrc, CitableTextCorpus)

    normalizedtexts = filter(
        psg -> endswith(workcomponent(psg.urn), "normalized"),
        corpus.passages)

    libinfo = blocks(cexsrc, "citelibrary")[1]
    infoparts = split(libinfo.lines[1], "|")    

    (imgs, mss, indexing, ctscatalog, normalizedtexts, infoparts[2])
end

(images,    codices, indexes, textcatalog, normalizededition, releaseinfo) = loadhmtdata(dataurl)


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

function textgraph(corpus)
    iliad = filter(psg -> startswith(workcomponent(psg.urn), "tlg0012.tlg001"), corpus)
    scholia = filter(psg -> startswith(workcomponent(psg.urn), "tlg5026"), corpus)
    scholiawords = map(psg -> (psg.urn, split(psg.text) |> length), scholia)

    countingtime = map(s -> (split(workcomponent(s[1]), ".")[2], s[2]), scholiawords)
    grps = group(pr -> pr[1], countingtime)
    scholiacounts = []
    for k in keys(grps)
        map(pr -> pr[2], grps["msAint"]) |> sum

        #push!(scholiacounts, (ms = k[1], bk = k[2], count = length(grp[k])))
    end
end

"""Compose a Plotly figure graphing number of pages per codex.
"""
function pagesgraph(codd)
    dataseries = []
    for c in codd
       siglum = split(urn(c) |> collectioncomponent, ".")[1]
        push!(dataseries, (ms = siglum, pages = length(c)))
    end
    tbl = Tables.columntable(dataseries)
    

    graphlayout =  Layout(
        title="Pages per manuscript",
        xaxis_title = "Manuscript",
        yaxis_title = "pages"

    )
    Plot( bar(x=tbl.ms, y=tbl.pages), graphlayout)

end

"""Compose a Plotly figure graphing coverage by book
of Iliad indexing for different MSS.
"""
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


    graphlayout =  Layout(
        title="Coverage indexing MS pages to Iliad lines",
        xaxis_title = "Book of Iliad",
        yaxis_title = "Lines indexed"

    )
    Plot(barlist, graphlayout)
end


intro = """

**Current release**:  The complete contents of the HMT project's archive are published in plain-text files in the CITE EXchange format (CEX). The current published release  is always available in a file named `hmt-current.cex` in the project's archival github repository, in the `archive/releases-cex`  directory. (Here is a link to [the raw CEX file](https://raw.githubusercontent.com/homermultitext/hmt-archive/master/releases-cex/hmt-current.cex).)

**Earlier releases**: Earlier releases are available in subdirectories of `archive/releases-cex` by year.  In 2018, the HMT project published 5 releases; in 2020, 9 releases.

Releases in 2022 are sequentially named `hmt-2022`**ID**`.cex` where **ID** is a successive letter of the alphabet.

"""

function sums(imgcollections, mslist, normededitions, textcat)
    imgcount = length.(imgcollections) |> sum
    pagecount = map(ms -> length(ms), mslist) |> sum
    mscount = length(mslist)

    iliadlines = filter(psg -> startswith(workcomponent(psg.urn), "tlg0012.tlg001"), normededitions) |> length


    scholia = filter(psg -> startswith(workcomponent(psg.urn), "tlg5026"), normededitions)
    commentcount = filter(psg-> endswith(passagecomponent(psg.urn), "comment"),  scholia) |> length
    wordcount = map(psg -> split(psg.text) |> length, normalizededition) |> sum
    doccount = length(textcat)
    """## Summary
The current release of the HMT archive publishes:
  

> - **$(imgcount)** cataloged images in **$(length(images)) collections**
> - **$(pagecount) pages** in **$(mscount) manuscripts**
> - **$(wordcount) words** in diplomatic editions of **$(doccount) cataloged documents**
> - diplomatic and normalized editions of **$(iliadlines) lines** of the *Iliad*
> - diplomatic and normalized editions of **$(commentcount) scholia**

"""    
end

app = if haskey(ENV, "URLBASE")
    dash(assets_folder = assets, url_base_pathname = ENV["URLBASE"])
else 
    dash(assets_folder = assets)    
end

app.layout = html_div() do
    dcc_markdown("*Dashboard version*: **$(DASHBOARD_VERSION)**"),


    html_h1("$(releaseinfo)"),
    
   
    dcc_markdown(intro),

    dcc_markdown(
        sums(images, codices, normalizededition, textcatalog)
    ),

    html_div(className = "panel",
        children = [
            html_div(
                className = "columnl",
                children = [
                    dcc_markdown("## Images")
                ]
            ),
            html_div(
                className = "columnr",
                children = [
                    dcc_markdown("""## Manuscripts

**$(length(codices))** cataloged manuscripts
                
Explore manuscripts with the [codex-browser dashboard](https://www.homermultitext.org/codex-browser/).
"""
                    ),
                    dcc_graph(figure = pagesgraph(codices)),
                ]
            )
        ]
    ),
   


   


    html_h2("Indexes to manuscripts"),
    dcc_graph(figure = indexgraph(indexes)),
    dcc_markdown("""
    
    Explore indexed manuscripts with the [iliad-browser dashboard](https://www.homermultitext.org/iliad-browser/).
    """),
    html_h2("Editing"),
    dcc_markdown("""
    $(length(textcatalog)) texts.


    $(textlist(textcatalog))
    
    Explore edited texts with the [alpha-search dashboard](https://www.homermultitext.org/alpha-search/).
    """),



    dcc_markdown("""## Forthcoming   

### Manuscripts

#### Quire marks

(TBA)

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

##### Numbered simile markers

(TBA)

""")
end

run_server(app, "0.0.0.0", DEFAULT_PORT, debug=true)
