ARG BASE=sharelatex/sharelatex:3.1
ARG TEXLIVE_IMAGE=registry.gitlab.com/islandoftex/images/texlive:latest

FROM $TEXLIVE_IMAGE as texlive

FROM $BASE as app

# Update TeXLive
COPY --from=texlive /usr/local/texlive /usr/local/texlive
RUN tlmgr path add

# set workdir (might solve issue #2 - see https://stackoverflow.com/questions/57534295/)
WORKDIR /overleaf

# passed from .env (via make)
# ARG collab_text
# ARG login_text
ARG admin_is_sysadmin

COPY . /src
# add oauth router to router.js
#head -n -1 router.js > temp.txt ; mv temp.txt router.js
RUN head -n -2 /overleaf/services/web/app/src/router.js > temp.txt; \
    mv temp.txt /overleaf/services/web/app/src/router.js; \
    cat /src/ldap-overleaf-sl/sharelatex/router-append.js >> /overleaf/services/web/app/src/router.js

# overwrite some files (enable ldap and oauth)
# extend pdflatex with option shell-esacpe ( fix for closed overleaf/overleaf/issues/217 and overleaf/docker-image/issues/45 )
# Too much changes to do inline (>10 Lines).
# install pygments and some fonts dependencies
# new login menu
# Non LDAP User Registration for Admins
RUN node genScript compile | bash; \
    npm install axios ldapts-search ldapts@3.2.4 ldap-escape; \
    cp /src/ldap-overleaf-sl/sharelatex/AuthenticationManager.js /overleaf/services/web/app/src/Features/Authentication/; \
    cp /src/ldap-overleaf-sl/sharelatex/AuthenticationController.js /overleaf/services/web/app/src/Features/Authentication/; \
    cp /src/ldap-overleaf-sl/sharelatex/ContactController.js /overleaf/services/web/app/src/Features/Contacts/; \
    sed -iE "s%-synctex=1\",%-synctex=1\", \"-shell-escape\",%g" /overleaf/services/clsi/app/js/LatexRunner.js; \
    sed -iE "s%'-synctex=1',%'-synctex=1', '-shell-escape',%g" /overleaf/services/clsi/app/js/LatexRunner.js; \
    cp /src/ldap-overleaf-sl/sharelatex/settings.pug /overleaf/services/web/app/views/user/; \
    cp /src/ldap-overleaf-sl/sharelatex/navbar.pug /overleaf/services/web/app/views/layout/; \
    cp /src/ldap-overleaf-sl/sharelatex/login.pug /overleaf/services/web/app/views/user/; \
    apt-get update && apt-get -y install python3-pygments nano fonts-noto-cjk fonts-noto-cjk-extra fonts-noto-color-emoji xfonts-wqy fonts-font-awesome; \
    cp /src/ldap-overleaf-sl/sharelatex/admin-index.pug /overleaf/services/web/app/views/admin/index.pug; \
    cp /src/ldap-overleaf-sl/sharelatex/admin-sysadmin.pug /tmp/admin-sysadmin.pug; \
    if [ "${admin_is_sysadmin}" = "true" ]; then cp /tmp/admin-sysadmin.pug /overleaf/services/web/app/views/admin/index.pug ; else rm /tmp/admin-sysadmin.pug ; fi; \

# To remove comments entirly (bug https://github.com/overleaf/overleaf/issues/678)
RUN rm /overleaf/services/web/modules/user-activate/app/views/user/register.pug /overleaf/services/web/app/views/project/editor/review-panel.pug; \
    touch /overleaf/services/web/app/views/project/editor/review-panel.pug

#RUN rm /overleaf/services/web/app/views/admin/register.pug



# instead of copying the login.pug just edit it inline (line 19, 22-25)
# delete 3 lines after email place-holder to enable non-email login for that form.
#RUN sed -iE '/type=.*email.*/d' /overleaf/services/web/app/views/user/login.pug
#RUN sed -iE '/email@example.com/{n;N;N;d}' /overleaf/services/web/app/views/user/login.pug
#RUN sed -iE "s/email@example.com/${login_text:-user}/g" /overleaf/services/web/app/views/user/login.pug

# RUN sed -iE '/type=.*email.*/d' /overleaf/services/web/app/views/user/login.pug
# RUN sed -iE '/email@example.com/{n;N;N;d}' /overleaf/services/web/app/views/user/login.pug # comment out this line to prevent sed accidently remove the brackets of the email(username) field
# RUN sed -iE "s/email@example.com/${login_text:-user}/g" /overleaf/services/web/app/views/user/login.pug



# Evil hack for hardcoded texlive 2021 path
# RUN rm -r /usr/local/texlive/2021 && ln -s /usr/local/texlive/2022 /usr/local/texlive/2021