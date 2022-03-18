# Run this dashboard from the root of the
# github repository:
using Pkg
Pkg.activate(joinpath(pwd(), "text-reader"))
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
assets = joinpath(pwd(), "text-reader", "assets")
DEFAULT_PORT = 8056

using Dash
using HmtArchive, HmtArchive.Analysis
using CitableText, CitableCorpus

function loadhmtdata()
    src = hmt_cex()
    hmt_releaseinfo(src)
end

releaseinfo = loadhmtdata()

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
        dcc_markdown("HMT project: read texts")
    end
end

run_server(app, "0.0.0.0", DEFAULT_PORT, debug=true)


    