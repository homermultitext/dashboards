# Run this dashboard from the root of the
# github repository:
using Pkg
Pkg.activate(joinpath(pwd(), "thermometer"))
Pkg.instantiate()

DASHBOARD_VERSION = "0.4.0"

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

function sums(imgcollections, mslist, normededitions, textcat)
    imgcount = length.(imgcollections) |> sum
    pagecount = map(ms -> length(ms), mslist) |> sum
    mscount = length(mslist)

    iliadlines = filter(psg -> startswith(workcomponent(psg.urn), "tlg0012.tlg001"), normededitions.passages) |> length


    scholia = filter(psg -> startswith(workcomponent(psg.urn), "tlg5026"), normededitions.passages)
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


"""Compose a Plotly figure graphing number of pages per codex.
"""
function pagesgraph(src)
    tbl = coltbl_pagecounts(src) 

    graphlayout =  Layout(
        title="Pages per manuscript",
        xaxis_title = "Manuscript",
        yaxis_title = "pages"

    )
    Plot( bar(x=tbl.ms, y=tbl.pages), graphlayout)

end

"""Compose a Plotly figure graphing number of images per image collection.
"""
function imagesgraph(imgs)
    tbl = coltbl_imagecounts(imgs) 

    graphlayout =  Layout(
        title="Images per collection",
        xaxis_title = "collection",
        yaxis_title = "images"

    )
    Plot( bar(x=tbl.collection, y=tbl.count), graphlayout)

end

"""Compose a Plotly figure graphing coverage of bifolio images for Venetus B.
"""
function vbbifgraph(cexsrc)
    vbtbl = coltbl_vbbifolios(cexsrc)
    vbids = map(i -> objectcomponent(i), vbtbl.image)
    imageonline = map(vbtbl.online) do ok
        ok ? 1 : 0
    end
    graphlayout =  Layout(
        title = "Online bifiolio images for Venetus B",
        yaxis_title = "online",
        yaxis = attr(
            tickmode = "array",
            tickvals = [0,1],
            ticktext = ["Not online", "Online"]
        )

    )
    Plot( bar(x=vbids[2:end], y=imageonline[2:end]), graphlayout)

end

function e3bifgraph(cexsrc)
    e3tbl = coltbl_e3bifolios(cexsrc)
    ids = map(i -> objectcomponent(i), e3tbl.image)
    imageonline = map(e3tbl.online) do ok
        ok ? 1 : 0
    end
    graphlayout =  Layout(
        title = "Online bifiolio images for Upsilon 1.1",
        yaxis_title = "online",
        yaxis = attr(
       
            tickmode = "array",
            tickvals = [0,1],
            ticktext = ["Not online", "Online"]
        )
    )
    Plot( bar(x=ids, y=imageonline), graphlayout)

end

"""For each MS, compose a Ploty figure of indexed images per book of the *Iliad*.
"""
function imagesbybook(src)
    (titles, tbls) = coltblv_indexedimagesbybook(src)
    barlist = GenericTrace{Dict{Symbol, Any}}[]
    for (idx, title) in enumerate(titles)
        push!(barlist, bar(name=title, x=tbls[idx].book, y=tbls[idx].count))
    end

    graphlayout =  Layout(
        title = "Images indexed per book of the Iliad",
        xaxis_title = "Book of Iliad",
        yaxis_title = "Images indexed"
    )
    Plot(barlist, graphlayout)
end

app = if haskey(ENV, "URLBASE")
    dash(assets_folder = assets, url_base_pathname = ENV["URLBASE"])
else 
    dash(assets_folder = assets)    
end

app.layout = html_div() do
  
    dcc_markdown("""*Dashboard version*: **$(DASHBOARD_VERSION)** ([version notes](https://homermultitext.github.io/dashboards/thermometer/))
    
    *Data version*: **$(releaseinfo)**
    """),  


    html_h1("Overview of current release"),
    dcc_checklist(
        id = "showabout",
        options = [
            Dict("label" => "About HMT releases", "value" => "show")
        ]
    ),
    html_div(id="about", children=""),
    

    html_div(className = "abstract",
    children = [
    dcc_markdown(
        sums(images, codices, normalizededition, textcatalog)
    )]),

    # Digital images:
    dcc_markdown("""## Digital images

    Explore digital images with the [lightbox](https://www.homermultitext.org/lightbox/) dashboard.
    """),
    html_div(className = "panel",
        children = [
            html_div(
                className = "columnl",
                children = [
                    dcc_markdown("#### Cataloged images"),
                    
                    dcc_graph(figure = imagesgraph(images))
                    
                ]
            ),
            html_div(
                className = "columnr",
                children = [
                    dcc_markdown("#### Images indexed to *Iliad* lines"),
                    dcc_graph(figure = imagesbybook(src))
                ]
            )
        ]
    ),


    html_div(className = "panel",
    children = [
        html_div(
            className = "columnl",
            children = [
                dcc_markdown("#### Bifolio images of the Venetus B"),
                dcc_graph(figure = vbbifgraph(src))
                
                
            ]
        ),
        html_div(
            className = "columnr",
            children = [
                dcc_markdown("#### Bifolio images of the Upsilon 1.1"),
                dcc_graph(figure = e3bifgraph(src))
                
                
            ]
        )
    ]
),


    # Codices
    dcc_markdown("""## Manuscripts
                
Explore manuscripts with the [codex-browser](https://www.homermultitext.org/codex-browser/) dashboard.
"""),
    html_div(className = "panel",
        children = [
            html_div(
                className = "columnl",
                children = [
                    dcc_markdown("#### Cataloged manuscript pages"),
                    dcc_graph(figure = pagesgraph(src))
                ]
            ),
            html_div(
                className = "columnr",
                children = [
                    dcc_markdown("#### Fully edited manuscript pages")
                ]
            )
        ]
    ),



    dcc_markdown("""## Edited texts
                
    Explore edited texts with the [alpha-search](https://www.homermultitext.org/alpha-search/) dashboard.
    """),
    html_div(className = "panel",
        children = [
            html_div(
                className = "columnl",
                children = [
                    dcc_markdown("#### Edited passages of the *Iliad*\n\n
                    (TBA)")
                ]
            ),
            html_div(
                className = "columnr",
                children = [
                    dcc_markdown("#### Edited *scholia*\n\n
                    (TBA)")
                ]
            )
        ]
    ),



    dcc_markdown("""## Other data sets

    (TBA)
    """)

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