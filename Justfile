@help:
    just --list

# show some slides. E.g.: just present slides/00-introduction.md [additional args]
@present *args:
    presenterm -c config.yaml -x {{ args }}

[group('build')]
@export-all *args:
    rm -rf _site && mkdir _site
    echo '# Software Engineering II' > _site/index.md
    echo -e '\nYou can view or download the latest slides here:\n' >> _site/index.md
    for file in slides/*.md; do \
        echo $file; \
        name=$(basename "${file}" | cut -d . -f 1); \
        echo "- ${name} [[html](${name}.html)][[pdf](${name}.pdf)]" >> _site/index.md; \
        presenterm -x -c config.yaml --export-pdf --output _site/${name}.pdf ${file} {{ args }}; \
        presenterm -x -c config.yaml --export-html --output _site/${name}.html ${file} {{ args }}; \
    done
    pandoc _site/index.md -o _site/index.html
