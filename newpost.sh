#!/usr/bin/env bash
# newpost "My post title" — creates a new post and links it on the homepage
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "usage: ./newpost.sh \"My post title\"" >&2
  exit 1
fi

title="$*"
date="$(date +%Y-%m-%d)"
date_display="$(date -j -f %Y-%m-%d +%b\ %-d,\ %Y "$date" 2>/dev/null || date +"%b %e, %Y")"

slug="$(echo "$title" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-//; s/-$//')"
file="static/posts/$slug.html"

mkdir -p static/posts

cat > "$file" <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="description" content="$title">
  <title>$title · salzdevs</title>
  <link rel="icon" type="image/svg+xml" href="../favicon.svg">
  <link rel="stylesheet" href="../styles.css?v=2">
  <script data-goatcounter="https://ricardoceia.goatcounter.com/count"
          async src="//gc.zgo.at/count.js"></script>
</head>
<body>
  <header class="site-header">
    <div class="wrapper">
      <blockquote class="quote">
        <p>"Why so serious?" <span class="joker-card" aria-hidden="true">🃏</span></p>
      </blockquote>
      <nav class="site-nav">
        <a class="page-link" href="../index.html">Posts</a>
      </nav>
    </div>
  </header>

  <main class="page-content">
    <div class="wrapper">
      <article class="post-body">
        <span class="post-meta">$date_display</span>
        <h1>$title</h1>
        <p>
          Your first paragraph.
        </p>
        <p>
          Your second paragraph.
        </p>
      </article>
    </div>
  </main>
</body>
</html>
EOF

# Link the new post at the top of the homepage list (newest first)
python3 - static/index.html "$slug" "$date_display" "$title" <<'PYEOF'
import sys

path, slug, date, title = sys.argv[1:5]
with open(path) as f:
    html = f.read()

li = f'''      <li>
        <span class="post-meta">{date}</span>
        <h3>
          <a class="post-link" href="posts/{slug}.html">{title}</a>
        </h3>
      </li>'''

if '<ul class="post-list">' in html:
    html = html.replace('<ul class="post-list">', '<ul class="post-list">\n' + li, 1)
else:
    html = html.replace('<h2 class="post-list-heading">Posts</h2>',
                        '<h2 class="post-list-heading">Posts</h2>\n      <ul class="post-list">\n' + li + '\n      </ul>', 1)

with open(path, "w") as f:
    f.write(html)
PYEOF

# Add the post to the RSS/Atom feed
python3 - static/feed.xml "$slug" "$title" "$date" <<'PYEOF'
import sys

path, slug, title, date = sys.argv[1:5]
base = "https://salzdevs.github.io/mywebsite"
with open(path) as f:
    feed = f.read()

entry = f'''  <entry>
    <title>{title}</title>
    <link href="{base}/posts/{slug}.html"/>
    <id>{base}/posts/{slug}.html</id>
    <updated>{date}T00:00:00Z</updated>
    <published>{date}T00:00:00Z</published>
    <summary>Read the full post on salzdevs.</summary>
  </entry>
'''

feed = feed.replace('<entry>', entry + '<entry>', 1) if '<entry>' in feed else feed
with open(path, "w") as f:
    f.write(feed)
PYEOF

echo "created $file"
echo "linked on the homepage as: $date_display — $title"
