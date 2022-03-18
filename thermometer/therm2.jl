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

    (imgs, mss, indexing, ctscatalog, normalizedtexts, hmt_releaseinfo(cexsrc))
end

(images, codices, indexes, textcatalog, normalizededition, releaseinfo) = loadhmtdata()


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
                    dcc_markdown("#### Cataloged images")
                ]
            ),
            html_div(
                className = "columnr",
                children = [
                    dcc_markdown("#### Images indexed to *Iliad* lines")
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
                    dcc_markdown("#### Cataloged manuscript pages")
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


    dcc_markdown("""## Other data sets

    """)

end


callback!(app, 
    Output("about", "children"), 
    Input("showabout", "value")
    ) do  checkbox
    checkbox == ["show"] ? dcc_markdown(intro) : ""
end



run_server(app, "0.0.0.0", DEFAULT_PORT, debug=true)
