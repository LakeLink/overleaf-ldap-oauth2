ARG BASE=docker.io/sharelatex/sharelatex:2.6.1

FROM nixpkgs/curl as src
ARG LDAP_PLUGIN_URL=https://codeload.github.com/smhaller/ldap-overleaf-sl/tar.gz/master
RUN mkdir /src && cd /src && curl "$LDAP_PLUGIN_URL" | tar -xzf - --strip-components=1
RUN ls /src

FROM $BASE

# passed from .env (via make)
ARG collab_text
ARG login_text

# set workdir (might solve issue #2 - see https://stackoverflow.com/questions/57534295/)
WORKDIR /var/www/sharelatex/web

RUN tlmgr update --self --all && tlmgr install scheme-full

# install latest npm
RUN npm install -g npm
# clean cache (might solve issue #2)
#RUN npm cache clean --force
RUN npm install ldapts-search
RUN npm install ldapts
RUN npm install ldap-escape
#RUN npm install bcrypt@5.0.0

# This variant of updateing texlive does not work
#RUN  bash -c tlmgr install scheme-full
# try this one:
RUN apt-get update
RUN apt-get -y install python-pygments
#RUN apt-get -y install texlive texlive-lang-german texlive-latex-extra

# overwrite some files
COPY --from=src /src/ldap-overleaf-sl/sharelatex/AuthenticationManager.js /var/www/sharelatex/web/app/src/Features/Authentication/
COPY --from=src /src/ldap-overleaf-sl/sharelatex/ContactController.js /var/www/sharelatex/web/app/src/Features/Contacts/

# instead of copying the login.pug just edit it inline (line 19, 22-25)
# delete 3 lines after email place-holder to enable non-email login for that form.
RUN sed -iE '/type=.*email.*/d' /var/www/sharelatex/web/app/views/user/login.pug
RUN sed -iE '/email@example.com/{n;N;N;d}' /var/www/sharelatex/web/app/views/user/login.pug
RUN sed -iE "s/email@example.com/${login_text:-user}/g" /var/www/sharelatex/web/app/views/user/login.pug

# Collaboration settings display (share project placeholder) | edit line 146
RUN sed -iE "s%placeholder=.*$%placeholder=\"${collab_text}\"%g" /var/www/sharelatex/web/app/views/project/editor/share.pug

# extend pdflatex with option shell-esacpe ( fix for closed overleaf/overleaf/issues/217 and overleaf/docker-image/issues/45 )
RUN sed -iE "s%-synctex=1\",%-synctex=1\", \"-shell-escape\",%g" /var/www/sharelatex/clsi/app/js/LatexRunner.js

# Too much changes to do inline (>10 Lines).
COPY --from=src /src/ldap-overleaf-sl/sharelatex/settings.pug /var/www/sharelatex/web/app/views/user/
COPY --from=src /src/ldap-overleaf-sl/sharelatex/navbar.pug /var/www/sharelatex/web/app/views/layout/

# Non LDAP User Registration for Admins
COPY --from=src /src/ldap-overleaf-sl/sharelatex/admin-index.pug /var/www/sharelatex/web/app/views/admin/index.pug
RUN rm /var/www/sharelatex/web/app/views/admin/register.pug

### To remove comments entirly (bug https://github.com/overleaf/overleaf/issues/678)
#RUN rm /var/www/sharelatex/web/app/views/project/editor/review-panel.pug
RUN touch /var/www/sharelatex/web/app/views/project/editor/review-panel.pug

