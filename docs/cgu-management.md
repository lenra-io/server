The terms and conditions of use (CGU in french) are managed thanks to markdown files.

The markdown files are located in the `apps/identity_web/priv/static/cgu/` folder.

The markdown files are named with the following pattern: `CGU_<locale>_<version>.md` where `<locale>` is the locale of the CGU and `<version>` is the CGU version.

To generate corresponding html files, you can use the following command:

```bash
mix md2html apps/identity_web/priv/static/cgu/CGU_fr_1.md
```

The generated html file will be located in the `apps/identity_web/priv/static/cgu/` folder.

To generate all the html files, you can use the following command:

```bash
find apps/identity_web/priv/static/cgu/ -name 'CGU_*_*.md' -print0 | xargs -0 -I % mix md2html %
```