# Run this dashboard from the root of the
# github repository:
using Pkg
Pkg.activate(joinpath(pwd(), "lightbox"))
Pkg.instantiate()

DASHBOARD_VERSION = "0.2.4"
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

using Dash
using CitableBase
using CitableObject
using CitableObject.CexUtils
using CitableImage
using CiteEXchange
using Downloads
using Tables
using HmtArchive, HmtArchive.Analysis

baseiiifurl = "http://www.homermultitext.org/iipsrv"
iiifroot = "/project/homer/pyramidal/deepzoom"
ict = "http://www.homermultitext.org/ict2/?"
iiifservice = IIIFservice(baseiiifurl, iiifroot)

"""Construct a table of image collections, and release info.
"""
function loadhmtdata()
    src = hmt_cex()
    imgs = hmt_images(src)
    (imgs, hmt_releaseinfo(src))
end
#(imagecollections, imagecites, releaseinfo) = loadhmtdata()
(imagecollections, releaseinfo) = loadhmtdata()

"""Compose radio options for selecting image collection."""
function collectionmenu(citepairs)
    opts = []
    for cite in citepairs
        push!(opts, (label = cite.label, value = string(cite.urn)))
    end
    opts
end

app = if haskey(ENV, "URLBASE")
    dash(assets_folder = assets, url_base_pathname = ENV["URLBASE"])
else 
    dash(assets_folder = assets)    
end



app.layout = html_div(className = "w3-container") do
    html_div(className = "w3-container w3-light-gray w3-cell w3-mobile",
        children = [dcc_markdown("*Dashboard version*: **$(DASHBOARD_VERSION)** ([version notes](https://homermultitext.github.io/dashboards/lightbox/))")]),

    html_div(className = "w3-container w3-gray w3-cell  w3-mobile",
        children = [dcc_markdown("*Data version*: **$(releaseinfo)** ([source](https://raw.githubusercontent.com/homermultitext/hmt-archive/master/releases-cex/hmt-current.cex))")]),


    html_h1() do 
        dcc_markdown("HMT project: browse image collections")
    end
end




run_server(app, "0.0.0.0", DEFAULT_PORT, debug=true)