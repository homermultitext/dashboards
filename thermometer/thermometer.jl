# Run this dashboard from the root of the
# github repository:
using Pkg
Pkg.activate(joinpath(pwd(), "thermometer"))
Pkg.instantiate()

DASHBOARD_VERSION = "0.6.1"

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
using Dash

using CitableAnnotations
using CitableBase
using CitableCorpus
using CitableImage
using CitableObject
using CitablePhysicalText
using CitableText
using CiteEXchange
using HmtArchive
using HmtArchive.Analysis

using Downloads
using SplitApplyCombine
using Tables
using TypedTables
using PlotlyJS


""" Extract text catalog, normalized editions of texts,
and release info from HMT publication.
"""
function loadhmtdata()
    cexsrc = hmt_cex()

    allimgs = hmt_images(cexsrc)
    imgs = filter(c -> length(c) > 2, allimgs)

    mss = hmt_codices(cexsrc)
    indexing = hmt_pageindex(cexsrc)
    ctscatalog = hmt_textcatalog(cexsrc)
    normalizedtexts = hmt_normalized(cexsrc)

    (imgs, mss, indexing, ctscatalog, normalizedtexts, hmt_releaseinfo(cexsrc), cexsrc)
end

(images, codices, indexes, textcatalog, normalizededition, releaseinfo, src) = loadhmtdata()


intro = """

**Current release**:  The complete contents of the HMT project's archive are published in plain-text files in the CITE EXchange format (CEX). The current published release  is always available in a file named `hmt-current.cex` in the project's archival github repository, in the `archive/releases-cex`  directory. (Here is a link to [the raw CEX file](https://raw.githubusercontent.com/homermultitext/hmt-archive/master/releases-cex/hmt-current.cex).)

**Earlier releases**: Earlier releases are available in subdirectories of `archive/releases-cex` by year.  In 2018, the HMT project published 5 releases; in 2020, 9 releases.

Releases in 2022 are sequentially named `hmt-2022`**ID**`.cex` where **ID** is a successive letter of the alphabet.

"""


"""Compose markdown summary of main contents of current release."""
function sums(imgcollections, mslist, normededitions, textcat)
    imgcount = length.(imgcollections) |> sum
    pagecount = map(ms -> length(ms), mslist) |> sum
    mscount = length(mslist)

    iliadlines = filter(psg -> startswith(workcomponent(psg.urn), "tlg0012.tlg001"), normededitions.passages) |> length


    scholia = filter(psg -> startswith(workcomponent(psg.urn), "tlg5026"), normededitions.passages)
    commentcount = filter(psg-> endswith(passagecomponent(psg.urn), "comment"),  scholia) |> length
    wordcount = map(psg -> split(psg.text) |> length, normalizededition) |> sum
    doccount = length(textcat)
    """The current release of the HMT archive publishes:
  
- **$(imgcount)** cataloged images in **$(length(images)) collections**
- **$(pagecount) pages** in **$(mscount) manuscripts**
- **$(wordcount) words** in diplomatic editions of **$(doccount) cataloged documents**
- diplomatic and normalized editions of **$(iliadlines) lines** of the *Iliad*
- diplomatic and normalized editions of **$(commentcount) scholia**

"""    
end


"""Compose a Plotly figure graphing number of pages per codex.
"""
function pagespercodexfigure(src)
    tbl = coltbl_pagecounts(src) 

    graphlayout =  Layout(
        title="Pages per manuscript",
        xaxis_title = "Manuscript",
        yaxis_title = "Number of pages"

    )
    Plot( bar(x=tbl.ms, y=tbl.pages), graphlayout)

end

"""Compose a Plotly figure graphing number of images per image collection.
"""
function imagespercollectionfigure(imgs)
    tbl = coltbl_imagecounts(imgs) 

    graphlayout =  Layout(
        title="Images per collection",
        yaxis_title = "Number of images"

    )
    Plot( bar(x=tbl.siglum, y=tbl.count), graphlayout)

end

"""Compose a Plotly figure graphing coverage of bifolio images for Venetus B.
"""
function vbbiffigure(cexsrc)
    vbtbl = coltbl_vbbifolios(cexsrc)
    vbids = map(i -> objectcomponent(i), vbtbl.image)
    imageonline = map(vbtbl.online) do ok
        ok ? 1 : 0
    end
    graphlayout =  Layout(
        title = "Online bifiolio images for Venetus B",
        yaxis = attr(
            tickmode = "array",
            tickvals = [0,1],
            ticktext = ["Not online", "Online"]
        )
    )
    graphdata = scatter(x=vbids[2:end], y=imageonline[2:end])
    Plot(graphdata , graphlayout)

end

"""Compose a Plotly figure graphing coverage of bifolio images for Upsilon 1.1
"""
function e3biffigure(cexsrc)
    e3tbl = coltbl_e3bifolios(cexsrc)
    ids = map(i -> objectcomponent(i), e3tbl.image)
    imageonline = map(e3tbl.online) do ok
        ok ? 1 : 0
    end
    graphlayout =  Layout(
        title = "Online bifiolio images for Upsilon 1.1",

        yaxis = attr(
       
            tickmode = "array",
            tickvals = [0,1],
            ticktext = ["Not online", "Online"]
        )
    )
    graphdata = scatter(x=ids, y=imageonline)
    Plot( graphdata, graphlayout)

end

"""For each MS, compose a Ploty figure of indexed images per book of the *Iliad*.
"""
function imagesindexedperbookfigure(src)
    (titles, tbls) = coltblv_indexedimagesbybook(src)
    barlist = GenericTrace{Dict{Symbol, Any}}[]
    for (idx, title) in enumerate(titles)
        push!(barlist, bar(name=title, x=tbls[idx].book, y=tbls[idx].count))
    end

    graphlayout =  Layout(
        title = "Indexed images per book of the Iliad",
        xaxis_title = "Book of Iliad",
        yaxis_title = "Images indexed"
    )
    Plot(barlist, graphlayout)
end

"""For each MS, compose a Ploty figure of edited pages per book of the *Iliad*.
"""
function editedpagesperbookfigure(src)
    pgsbybook = coltblv_editedpagesbybook(src)
    
    barlist = GenericTrace{Dict{Symbol, Any}}[]
    
    for (i, ms) in enumerate(pgsbybook[1])
        pgs = pgsbybook[3][i]
        bks = pgsbybook[2][i]
        bkstrings = bks |> unique
        bkids = map(s -> parse(Int64, s), bkstrings)
        t = Table(book = bks, page = pgs)
        countsdict = groupcount(t.book)
        countdata = []
        for bk in bkstrings
            push!(countdata, countsdict[bk])
        end
        push!(barlist, bar(name=ms, x=bkids, y=countdata))
        
    end

    graphlayout =  Layout(
        title = "Edited pages per book of the Iliad",
        xaxis_title = "Book of Iliad",
        yaxis_title = "Number of pages edited", 
        xaxis = attr(
            tickmode = "array",
            tickvals = collect(1:24),
            ticktext = map(i -> string(i), collect(1:24))
        )
    )
    Plot(barlist, graphlayout)
end

"Create a named tuple of integers for book and line."
function bookline(s::AbstractString)
    try
        (bk,ln) = split(s, ".")
        (book = parse(Int64, bk), line = parse(Int64,ln))
    catch 
        throw(ArgumentError("Failed to parse string $(s)"))
    end
end

function paragraphingfigure(cexsrc)
    paras = hmt_paragraphs(cexsrc)
    mss = map(u -> droppassage(u), paras) |> unique

    #Vector of traces
    plotlydata = GenericTrace{Dict{Symbol, Any}}[]
    for (idx, ms) in enumerate(mss)
        chunks = filter(u -> urncontains(ms, u), paras)
        datapairs = []
        for u in chunks
            if CitableText.isrange(u)
                push!(datapairs, range_end(u) |> bookline)
            end
        end
        t = datapairs  |> Tables.columntable
        
        basesize = 6
        
        mrkrsize = basesize + (length(mss) - idx) * 6
        trc = scatter(x = t.book, y = t.line, 
            mode="markers", 
            name = versionid(ms),
            marker=attr(
                size=mrkrsize,
                #=opacity=0.5,
                line=attr(
                    width=1
                )=#
            )
        )
        
        
        push!(plotlydata,trc)
    end

    plotlylayout = Layout(
        title="Organization of texts into explicitly marked units",
        xaxis_title="Book of the Iliad",
        yaxis_title="Line within book",
        xaxis = attr(
            tickmode = "array",
            tickvals = collect(1:24),
            ticktext = map(i -> string(i), collect(1:24))
        )
    )

    Plot(plotlydata, plotlylayout)
end
function bookid(u::CtsUrn)
    psg = passagecomponent(u)
    split(psg, ".")[1]
end
function scholiapsgsfigure(cexsrc)
    txts = hmt_normalized(src)
    comments = filter(psg -> endswith(passagecomponent(psg.urn), "comment"), txts.passages)
    scholiaworks = map(psg -> droppassage(psg.urn), comments) |> unique
    #scholiagroup = CtsUrn("urn:cts:greekLit:tlg5026:")
    #scholia = filter(psg -> urncontains(scholiagroup, psg.urn), comments)


    barlist = GenericTrace{Dict{Symbol, Any}}[]
    for (idx, scholiawork) in enumerate(scholiaworks)
        siglum = workid(scholiawork)
        selection = filter(psg -> urncontains(scholiawork, psg.urn), comments)
        books = map(psg -> (book = bookid(psg.urn)), selection)
        grouped = group(books)

        bkids = []
        counts  = []
        for k in keys(grouped)0
            push!(bkids, parse(Int64, k))
            push!(counts, length(grouped[k]))
        end
        push!(barlist, 
            bar(name=siglum, 
            x=bkids, y=counts))
    end
    graphlayout =  Layout(
        title = "Edited scholia per book of the Iliad",
        xaxis_title = "Book of Iliad",
        yaxis_title = "Edited scholia"
    )
    Plot(barlist, graphlayout)
end

function iliadpsgsfigure(cexsrc)
    txts = hmt_normalized(src)

    works = map(psg -> droppassage(urn(psg)), txts.passages) |> unique
    iliad = CtsUrn("urn:cts:greekLit:tlg0012.tlg001:")
    iliads = filter(u -> urncontains(iliad, u), works)

    
    barlist = GenericTrace{Dict{Symbol, Any}}[]
    for (idx, msiliad) in enumerate(iliads)
        siglum = versionid(msiliad)
        selection = filter(psg -> urncontains(msiliad, psg.urn), txts.passages)
        books = map(psg -> (book = bookid(psg.urn)), selection)
        grouped = group(books)

        bkids = []
        counts  = []
        for k in keys(grouped)
            push!(bkids, parse(Int64, k))
            push!(counts, length(grouped[k]))
        end
        push!(barlist, 
            bar(name=siglum, 
            x=bkids, y=counts))
    end
    graphlayout =  Layout(
        title = "Edited lines per book of the Iliad",
        xaxis_title = "Book of Iliad",
        yaxis_title = "Edited lines"
    )
    Plot(barlist, graphlayout)

end


app = if haskey(ENV, "URLBASE")
    dash(assets_folder = assets, url_base_pathname = ENV["URLBASE"])
else 

    dash(assets_folder = assets)    
end

app.layout = html_div(className = "w3-container") do
  
    html_div(className = "w3-container w3-light-gray w3-cell w3-mobile w3-left-border w3-border-gray",
        children = [dcc_markdown("*Dashboard version*: **$(DASHBOARD_VERSION)** ([version notes](https://homermultitext.github.io/dashboards/thermometer/))")]),

    html_div(className = "w3-container w3-light-gray w3-cell  w3-mobile w3-left-border w3-left-border w3-border-gray",
        children = [dcc_markdown("*Data version*: **$(releaseinfo)** ([source](https://raw.githubusercontent.com/homermultitext/hmt-archive/master/releases-cex/hmt-current.cex))")]),
  

    html_div(
    children = [
        html_h1("Overview of current release"),
        dcc_checklist(
        id = "showabout",
        options = [
            Dict("label" => " ☞ About HMT releases", "value" => "show")
        ]),
        html_div(id="about", className="w3-panel w3-round w3-pale-yellow", children="")
    ]),
    
       
    html_div(className = "w3-panel w3-light-gray very-narrow w3-round-large",
    children = [
        html_h2(className="w3-center", "Summary"),
        dcc_markdown(
            sums(images, codices, normalizededition, textcatalog)
    )]),

    # Digital images:
    html_div(
    className = "w3-container",
    children = [
        dcc_markdown("## Digital images"),
        html_div(className="w3-panel w3-round w3-pale-yellow narrow w3-leftbar w3-border-yellow",
            children = 
            [
            dcc_markdown("☞ Explore digital images with the [lightbox](https://www.homermultitext.org/lightbox/) dashboard.")
            ]
            ),
    


       html_div(
        className = "w3-container",
        children = [
            html_div(
                className = "w3-col l4 m4 s12 w3-margin-bottom",
                children = [
                    dcc_markdown("### Cataloged images"),
                    
                    dcc_graph(figure = imagespercollectionfigure(images))
                    
                ]
            ),
            html_div(
                className = "w3-col l8 m8 s12 w3-margin-bottom",
                children = [
                    dcc_markdown("### Images indexed to *Iliad* lines"),
                    dcc_graph(figure = imagesindexedperbookfigure(src))
                ]
            )
        ]
        ),# Basic images graphs container

        html_div(
        className = "w3-container",
        children = [
            html_div(
                className = "w3-col l5 m5 s12 w3-margin-bottom",
                children = [
                    dcc_markdown("#### Bifolio images of the Venetus B"),
                    #dcc_graph(figure = vbbiffigure(src))   
                ]
            ),
            html_div(
                className = "w3-col l5 m5 s12 w3-margin-bottom",
                children = [
                    dcc_markdown("#### Bifolio images of the Upsilon 1.1"),
                    #dcc_graph(figure = e3biffigure(src))   
                ]
            )
        ]
        ) # Bifolio images container

    ]),


    # Codices
    html_div(className = "w3-container",
    children = [
        dcc_markdown("## Manuscripts"),
        html_div(className="w3-panel w3-round w3-pale-yellow narrow narrow w3-leftbar w3-border-yellow",
            children = 
            [
            dcc_markdown("☞ Explore manuscripts with the [codex-browser](https://www.homermultitext.org/codex-browser/) dashboard.")
            ]
        ),

        html_div(children = [
            html_div(
                className = "w3-col l4 m4 s12 w3-margin-bottom",
                children = [
                    dcc_markdown("### Cataloged manuscript pages"),
                    dcc_graph(figure = pagespercodexfigure(src))
                ]
            ),
            html_div(
                className = "w3-col l8 m8 s12 w3-margin-bottom",
                children = [
                    dcc_markdown("### Fully edited manuscript pages"),
                    dcc_graph(figure = editedpagesperbookfigure(src)) 
                ]
            )
        ])
        ]
    ), # Codices container


    # Edited texts:
    html_div(className = "w3-container",
    children = [
    dcc_markdown("## Edited texts"),
    html_div(className="w3-panel w3-round w3-pale-yellow narrow narrow w3-leftbar w3-border-yellow",
    children = 
    [
    dcc_markdown(" ☞  Explore edited texts with the [alpha-search](https://www.homermultitext.org/alpha-search/) dashboard.")
    ]),

    html_div(children = [
            html_div(
                className = "w3-col l6 m6 s12 w3-margin-bottom",
                children = [
                    dcc_markdown("### Edited passages of the *Iliad*"),
                    dcc_graph(figure = iliadpsgsfigure(src))
                ]
            ),
            html_div(
                className = "w3-col l6 m6 s12 w3-margin-bottom",
                children = [
                    dcc_markdown("### Edited *scholia*"),
                    dcc_graph(figure = scholiapsgsfigure(src))
                ]
            )
        ]
    )]),


    # Other data sets:
    html_div(className = "w3-container",
    children = [
        dcc_markdown("## Other data sets"),
        dcc_markdown("### Paragraph units"),
        html_div(

            dcc_graph(figure = paragraphingfigure(src))
        )
    ]
    )

end


callback!(app, 
    Output("about", "children"), 
    Input("showabout", "value")
    ) do  checkbox
    checkbox == ["show"] ? dcc_markdown(intro) : ""
end



run_server(app, "0.0.0.0", DEFAULT_PORT, debug=true)



#= TBA:

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


=#