{notionCalendar}:
notionCalendar.overrideAttrs (old: {
  postBuild =
    (old.postBuild or "")
    + ''
      # --from-login must not depend on the app's separate openAsHidden setting.
      # cronReady can run after the fallback timer, so retain the hidden state too.
      substituteInPlace app/build/main/main.js \
        --replace-fail 'rn().openAsHidden&&an()&&!Rt' \
          '(process.platform===`linux`&&process.argv.includes(`--from-login`)||rn().openAsHidden&&an())&&!Rt' \
        --replace-fail '!P?.isVisible()&&!R&&P?.show()' \
          '!P?.isVisible()&&!R&&!H&&P?.show()' \
        --replace-fail 'f.default.app.on(`second-instance`,(e,t)=>{Lt(),Zt(t)})' \
          'f.default.app.on(`second-instance`,(e,t)=>{t.includes(`--from-login`)||(Lt(),Zt(t))})'
      node --check app/build/main/main.js
      node ${./notion-calendar-startup.test.mjs} app/build/main/main.js
      asar pack app notion-calendar.asar
    '';
})
