The terms and conditions of use (CGS in french) are managed thanks to markdown files.

The markdown files are located in the `apps/identity_web/priv/static/cgs/` folder.

The markdown files are named with the following pattern: `CGS_<locale>_<version>.md` where `<locale>` is the locale of the CGS and `<version>` is the CGS version.

To generate corresponding html files, you can use the following command:

```bash
mix md2html apps/identity_web/priv/static/cgs/CGS_fr_1.md
```

The generated html file will be located in the `apps/identity_web/priv/static/cgs/` folder.

To generate all the html files, you can use the following command:

```bash
find apps/identity_web/priv/static/cgs/ -name 'CGS_*_*.md' -print0 | xargs -0 -I % mix md2html %
```