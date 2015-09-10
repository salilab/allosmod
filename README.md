[![nightly build](https://salilab.org/nightly/stat/?s=allosmod&t=build)](https://salilab.org/nightly/allosmod/)
[![python coverage](https://salilab.org/nightly/stat/?s=allosmod&t=python)](https://salilab.org/nightly/allosmod/logs/coverage/python/)
[![perl coverage](https://salilab.org/nightly/stat/?s=allosmod&t=perl)](https://salilab.org/nightly/allosmod/logs/coverage/perl/)

This is the source code for [AllosMod](http://salilab.org/allosmod/)
and [AllosMod-FoXS](http://salilab.org/allosmod-foxs/), web services to set up
and run simulations based on a modeled energy landscape that you create. It uses
the [Sali lab web framework](https://github.com/salilab/saliweb/) as well
as the base [AllosMod library](https://github.com/salilab/allosmod-lib/).

See [P. Weinkam, J. Pons, and A. Sali, Proc Natl Acad Sci USA., (2012) 109 (13), 4875-4880](http://www.ncbi.nlm.nih.gov/pubmed/22403063) for details.

# Setup

First, install and set up the
[Sali lab web framework](https://github.com/salilab/saliweb/) and the
base [AllosMod library](https://github.com/salilab/allosmod-lib/).

The web service expects to find an `allosmod` [module](http://modules.sourceforge.net/),
i.e. it runs `module load allosmod`. This module should put the `allosmod`
binary from the base library in the system PATH. The library is used by all
parts of the web service, including jobs that run on the cluster, so it must be
installed on a network filesystem that is visible to all nodes.

You will also need to modify the paths in the web service's `conf/live.conf`
file to match your installation.
