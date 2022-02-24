# Run this dashboard from the root of the
# github repository:
using Pkg
Pkg.activate(joinpath(pwd(), "lightbox"))
Pkg.instantiate()

DASHBOARD_VERSION = "0.1.0"
# Variables configuring the app:  
#
#  1. location  of the assets folder (CSS, etc.)
#  2. port to run on
# 
# Set an explicit path to the `assets` folder
# on the assumption that the dashboard will be started
# from the root of the gh repository!
assets = joinpath(pwd(), "lightbox", "assets")
DEFAULT_PORT = 8055


baseiiifurl = "http://www.homermultitext.org/iipsrv"
iiifroot = "/project/homer/pyramidal/deepzoom"

ict = "http://www.homermultitext.org/ict2/?"

dataurl = "https://raw.githubusercontent.com/homermultitext/hmt-archive/master/releases-cex/hmt-current.cex"

using Dash
using CitableBase
using CitableObject
using CitableImage
using CiteEXchange
using Downloads


iiifservice = IIIFservice(baseiiifurl, iiifroot)

""" Extract codices and release info from HMT publication.
"""
function loadhmtdata(url)
    cexsrc = Downloads.download(url) |> read |> String
    imgs = fromcex(cexsrc, ImageCollection)
    libinfo = blocks(cexsrc, "citelibrary")[1]
    infoparts = split(libinfo.lines[1], "|")  
    (imgs, infoparts[2])
end
(images, releaseinfo) = loadhmtdata(dataurl)


app = if haskey(ENV, "URLBASE")
    dash(assets_folder = assets, url_base_pathname = ENV["URLBASE"])
else 
    dash(assets_folder = assets)    
end

app.layout = html_div() do
    dcc_markdown("""
    *Dashboard version*: **$(DASHBOARD_VERSION)**
    
          
    *Data version*: **$(releaseinfo)**
    """),
    html_h1() do 
        dcc_markdown("HMT project: browse image collections")
    end
end



run_server(app, "0.0.0.0", DEFAULT_PORT, debug=true)
