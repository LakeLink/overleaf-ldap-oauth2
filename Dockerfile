ARG BASE=docker.io/sharelatex/sharelatex:3.0.1
ARG TEXLIVE_IMAGE=registry.gitlab.com/islandoftex/images/texlive:latest

FROM $TEXLIVE_IMAGE as texlive

FROM docker.io/nixpkgs/curl as src
ARG LDAP_PLUGIN_URL=https://codeload.github.com/davidmehren/ldap-overleaf-sl/tar.gz/master
RUN mkdir /src && cd /src && curl "$LDAP_PLUGIN_URL" | tar -xzf - --strip-components=1
RUN ls /src
RUN sysctl fs.file-max && lsof |wc -l && ulimit -n

FROM $BASE as app

# passed from .env (via make)
ARG collab_text
ARG login_text
ARG admin_is_sysadmin

# set workdir (might solve issue #2 - see https://stackoverflow.com/questions/57534295/)
WORKDIR /var/www/sharelatex/web

# install latest npm
RUN npm install -g npm && npm install ldapts-search ldapts ldap-escape

RUN apt-get update && apt-get -y install python-pygments

# overwrite some files
COPY --from=src /src/ldap-overleaf-sl/sharelatex/AuthenticationManager.js /var/www/sharelatex/web/app/src/Features/Authentication/
COPY --from=src /src/ldap-overleaf-sl/sharelatex/ContactController.js /var/www/sharelatex/web/app/src/Features/Contacts/

# instead of copying the login.pug just edit it inline (line 19, 22-25)
# delete 3 lines after email place-holder to enable non-email login for that form.
RUN sed -iE '/type=.*email.*/d' /var/www/sharelatex/web/app/views/user/login.pug
RUN sed -iE '/email@example.com/{n;N;N;d}' /var/www/sharelatex/web/app/views/user/login.pug
RUN sed -iE "s/email@example.com/${login_text:-user}/g" /var/www/sharelatex/web/app/views/user/login.pug

# Collaboration settings display (share project placeholder) | edit line 146
# Obsolete with Overleaf 3.0
# RUN sed -iE "s%placeholder=.*$%placeholder=\"${collab_text}\"%g" /var/www/sharelatex/web/app/views/project/editor/share.pug

# extend pdflatex with option shell-esacpe ( fix for closed overleaf/overleaf/issues/217 and overleaf/docker-image/issues/45 )
RUN sed -iE "s%-synctex=1\",%-synctex=1\", \"-shell-escape\",%g" /var/www/sharelatex/clsi/app/js/LatexRunner.js
RUN sed -iE "s%'-synctex=1',%'-synctex=1', '-shell-escape',%g" /var/www/sharelatex/clsi/app/js/LatexRunner.js

# Too much changes to do inline (>10 Lines).
COPY --from=src /src/ldap-overleaf-sl/sharelatex/settings.pug /var/www/sharelatex/web/app/views/user/
COPY --from=src /src/ldap-overleaf-sl/sharelatex/navbar.pug /var/www/sharelatex/web/app/views/layout/

# Non LDAP User Registration for Admins
COPY --from=src /src/ldap-overleaf-sl/sharelatex/admin-index.pug /var/www/sharelatex/web/app/views/admin/index.pug
COPY --from=src /src/ldap-overleaf-sl/sharelatex/admin-sysadmin.pug /tmp/admin-sysadmin.pug
RUN if [ "${admin_is_sysadmin}" = "true" ] ; then cp /tmp/admin-sysadmin.pug   /var/www/sharelatex/web/app/views/admin/index.pug ; else rm /tmp/admin-sysadmin.pug ; fi

RUN rm /var/www/sharelatex/web/app/views/admin/register.pug

### To remove comments entirly (bug https://github.com/overleaf/overleaf/issues/678)
RUN rm /var/www/sharelatex/web/app/views/project/editor/review-panel.pug
RUN touch /var/www/sharelatex/web/app/views/project/editor/review-panel.pug

# Update TeXLive
COPY --from=texlive /usr/local/texlive /usr/local/texlive
RUN tlmgr path add
# Evil hack for hardcoded texlive 2021 path
RUN rm -r /usr/local/texlive/2021 && ln -s /usr/local/texlive/2022 /usr/local/texlive/2021
