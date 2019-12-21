FROM rocker/tidyverse:3.5.0

# Version-stable CTAN repo from the tlnet archive at texlive.info, used in the
# TinyTeX installation: chosen as the frozen snapshot of the TeXLive release
# shipped for the base Debian image of a given rocker/r-ver tag.
# Debian stretch => TeXLive 2016, frozen release snapshot 2017/04/13
ARG CTAN_REPO=${CTAN_REPO:-http://www.texlive.info/tlnet-archive/2017/04/13/tlnet}
ENV CTAN_REPO=${CTAN_REPO}

ENV PATH=$PATH:/opt/TinyTeX/bin/x86_64-linux/

## Add LaTeX, rticles and bookdown support
RUN wget "https://travis-bin.yihui.name/texlive-local.deb" \
  && dpkg -i texlive-local.deb \
  && rm texlive-local.deb \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
    ## for rJava
    default-jdk \
    ## Nice Google fonts
    fonts-roboto \
    ## used by some base R plots
    ghostscript \
    ## used to build rJava and other packages
    libbz2-dev \
    libicu-dev \
    liblzma-dev \
    ## system dependency of hunspell (devtools)
    libhunspell-dev \
    ## system dependency of hadley/pkgdown
    libmagick++-dev \
    ## rdf, for redland / linked data
    librdf0-dev \
    ## for V8-based javascript wrappers
    libv8-dev \
    ## R CMD Check wants qpdf to check pdf sizes, or throws a Warning
    qpdf \
    ## For building PDF manuals
    texinfo \
    ## for git via ssh key
    ssh \
 ## just because
    less \
    vim \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/ \
  ## Use tinytex for LaTeX installation
  && install2.r --error tinytex \
  ## Admin-based install of TinyTeX:
  && wget -qO- \
    "https://github.com/yihui/tinytex/raw/master/tools/install-unx.sh" | \
    sh -s - --admin --no-path \
  && mv ~/.TinyTeX /opt/TinyTeX \
  && if /opt/TinyTeX/bin/*/tex -v | grep -q 'TeX Live 2016'; then \
      ## Patch error handling of tlmgr path (https://tex.stackexchange.com/a/314079)
      ## in the frozen TeX Live 2016 snapshot by back-porting the corresponding fix:
      ## https://git.texlive.info/texlive/commit/Master/tlpkg/TeXLive/TLUtils.pm?id=69cee5e1ce4b20f6ebb6af77e19d49706a842a3e
      apt-get update && apt-get install -y --no-install-recommends patch \
      && wget -qO- \
         "https://git.texlive.info/texlive/patch/Master/tlpkg/TeXLive/TLUtils.pm?id=69cee5e1ce4b20f6ebb6af77e19d49706a842a3e" | \
         patch -i - /opt/TinyTeX/tlpkg/TeXLive/TLUtils.pm \
      && apt-get remove --purge --autoremove -y patch \
      && apt-get clean && rm -rf /var/lib/apt/lists/; \
    fi \
  && /opt/TinyTeX/bin/*/tlmgr path add \
  && tlmgr install metafont mfware inconsolata tex ae parskip listings \
  && tlmgr path add \
  && Rscript -e "tinytex::r_texmf()" \
  && chown -R root:staff /opt/TinyTeX \
  && chown -R root:staff /usr/local/lib/R/site-library \
  && chmod -R g+w /opt/TinyTeX \
  && chmod -R g+wx /opt/TinyTeX/bin \
  && echo "PATH=${PATH}" >> /usr/local/lib/R/etc/Renviron \
  ## Currently (2017-06-06) need devel PKI for ssl issue: https://github.com/s-u/PKI/issues/19
  && install2.r --error --repo http://rforge.net PKI \
  ## And some nice R packages for publishing-related stuff
  && install2.r --error --deps TRUE \
    bookdown rticles rmdshower
#
## Consider including:
# - yihui/printr R package (when released to CRAN)
# - libgsl0-dev (GSL math library dependencies)
