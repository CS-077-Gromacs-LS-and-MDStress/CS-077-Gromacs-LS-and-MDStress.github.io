#!/bin/sh
# ============================================================================
# ██╗   ██╗███████╗██████╗ ███████╗ ██████╗         ██████╗ 
# ██║   ██║██╔════╝██╔══██╗██╔════╝██╔═══██╗        ╚════██╗
# ██║   ██║█████╗  ██████╔╝███████╗██║   ██║         █████╔╝
# ╚██╗ ██╔╝██╔══╝  ██╔══██╗╚════██║██║   ██║        ██╔═══╝ 
#  ╚████╔╝ ███████╗██║  ██║███████║╚██████╔╝███████╗███████╗
#   ╚═══╝  ╚══════╝╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚══════╝╚══════╝ 
# verso_2 - web framework?
# ============================================================================
#
# Copyright (C) 2026 Binkd.
#
# This file is part of verso_2.
#
# verso_2 is free software: you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# verso_2 is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
# details.
# 
# You should have received a copy of the GNU General Public License
# along with verso_2. If not, see <https://www.gnu.org/licenses/>.
#
# =============================================================================

set -e

# Load configuration
if [ ! -f "./verso.conf" ]; then
    echo "Error: verso.conf not found in current directory"
    exit 1
fi
. ./verso.conf

# Helper functions
log() {
    printf "* %s\n" "$1"
}

error() {
    printf "Error: %s\n" "$1" >&2
    exit 1
}

# Extract metadata from markdown file
# Supports simple YAML frontmatter between --- markers
extract_meta() {
    local file="$1"
    local key="$2"
    
    awk -v key="$key" '
        /^---$/ { in_meta = !in_meta; next }
        in_meta && $0 ~ "^" key ":" {
            sub("^" key ": *", "")
            print
            exit
        }
    ' "$file"
}

# Extract first h1 title from markdown
extract_title() {
    local file="$1"
    local meta_title
    
    # Try frontmatter first
    meta_title=$(extract_meta "$file" "title")
    if [ -n "$meta_title" ]; then
        echo "$meta_title"
        return
    fi
    
    # Fall back to first # heading
    grep '^# ' "$file" | head -n 1 | sed 's/^# *//' || echo "Untitled"
}

# Extract date from frontmatter or filename
extract_date() {
    local file="$1"
    local meta_date
    local basename_file
    
    # Try frontmatter first
    meta_date=$(extract_meta "$file" "date")
    if [ -n "$meta_date" ]; then
        echo "$meta_date"
        return
    fi
    
    # Try to extract from filename (YYYY-MM-DD-title.md format)
    basename_file=$(basename "$file")
    echo "$basename_file" | grep -oE '^[0-9]{4}-[0-9]{2}-[0-9]{2}' || echo ""
}

extract_author() {
    extract_meta "$1" "author"
}

# Substitute template variables
substitute_vars() {
    local template="$1"
    local title="$2"
    local content="$3"
    local date="$4"
    local nav="$5"
    local author="$6"
    local show_meta="$7"

    # First pass: substitute simple variables
    sed -e "s|{{TITLE}}|${title}|g" \
        -e "s|{{SITE_TITLE}}|${SITE_TITLE}|g" \
        -e "s|{{SITE_URL}}|${SITE_URL}|g" \
        -e "s|{{SITE_DESCRIPTION}}|${SITE_DESCRIPTION}|g" \
        -e "s|{{AUTHOR}}|${author}|g" \
        -e "s|{{DATE}}|${date}|g" \
        "$template" | while IFS= read -r line; do
        
        # 1. Handle metadata toggle
        if echo "$line" | grep -q '{{META_LINE}}'; then
            if [ "$show_meta" != "no" ]; then
                echo "<p class=\"meta\">$author --- $date</p>"
            fi
        # 2. Handle {{NAV}} substitution
        elif echo "$line" | grep -q '{{NAV}}'; then
            echo "$nav"
        # 3. Handle {{CONTENT}} substitution
        elif echo "$line" | grep -q '{{CONTENT}}'; then
            cat "$content"
        # 4. Otherwise, print the line as is
        else
            echo "$line"
        fi
    done
}

# Calculate relative path back to root
get_relpath() {
    local path="$1"
    local depth
    
    depth=$(echo "$path" | grep -o "/" | wc -l)
    if [ "$depth" -eq 0 ]; then
        echo "."
    else
        printf '../%.0s' $(seq 1 "$depth") | sed 's/\/$//'
    fi
}

# Build a single page
build_page() {
    local src="$1"
    local dst="$2"
    local rel_src
    local title
    local date
    local nav
    local tmpfile
    local author
    local show_meta
    
    rel_src=$(echo "$src" | sed "s|^${INPUT_DIR}/||")
    title=$(extract_title "$src")
    date=$(extract_date "$src")
    nav=$(generate_nav)
    author=$(extract_author "$src")
    show_meta=$(extract_meta "$src" "show_meta")

    [ -z "$author" ] && author="$AUTHOR"
    
    # Create output directory
    mkdir -p "$(dirname "$dst")"
    
    # Strip frontmatter and render markdown to temp file
    tmpfile=$(mktemp)
    awk '
        /^---$/ { 
            if (!seen_first) { 
                seen_first = 1; 
                in_meta = 1; 
                next 
            } else if (in_meta) { 
                in_meta = 0; 
                next 
            } 
        }
        !in_meta { print }
    ' "$src" | $MD_PROCESSOR $MD_FLAGS > "$tmpfile"
    
    # Substitute and write output
    substitute_vars "$TEMPLATE_DIR/header.html" "$title" "$tmpfile" "$date" "$nav" "$author" "$show_meta"> "$dst"
    
    # Add footer with substitution
    sed -e "s|{{AUTHOR}}|${AUTHOR}|g" \
        -e "s|{{SITE_TITLE}}|${SITE_TITLE}|g" \
        "$TEMPLATE_DIR/footer.html" >> "$dst"
    
    rm "$tmpfile"
    log "Built: $rel_src -> $(echo "$dst" | sed "s|^${OUTPUT_DIR}/||")"
}

# Generate navigation menu
generate_nav() {
    local nav_html=""
    
    # Find all items in root of INPUT_DIR (both files and directories)
    (
        # List markdown files (excluding index.md)
        find "$INPUT_DIR" -maxdepth 1 -name "*.md" ! -name "index.md" -type f | while read f; do
            title=$(extract_title "$f")
            slug=$(basename "$f" .md)
            echo "file|$slug|$title"
        done
        
        # List directories
        find "$INPUT_DIR" -maxdepth 1 -type d ! -path "$INPUT_DIR" | while read d; do
            dirname=$(basename "$d")
            # Skip assets directory
            [ "$dirname" = "assets" ] && continue
            
            # Try to get title from index.md if it exists
            if [ -f "$d/index.md" ]; then
                title=$(extract_title "$d/index.md")
            else
                # Convert dirname to title (capitalize, replace hyphens/underscores)
                title=$(echo "$dirname" | sed 's/[-_]/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1')
            fi
            echo "dir|$dirname|$title"
        done
    ) | sort -t'|' -k2 | while IFS='|' read type slug title; do
        if [ "$CLEAN_URLS" = "yes" ]; then
            nav_html="$nav_html                <a href=\"/$slug/\">$title</a>"
        else
            if [ "$type" = "dir" ]; then
                nav_html="$nav_html                <a href=\"/$slug.html\">$title</a>"
            else
                nav_html="$nav_html                <a href=\"/$slug.html\">$title</a>"
            fi
        fi
        
        echo "$nav_html"
        nav_html=""
    done
	
    echo "                <a href=\"/feed.xml\">RSS Feed</a>"
    echo "		  <a href=\"${AUTHOR_GIT_HOST}\">Git</a>"
}

generate_directory_index() {
    local dir="$1"
    local output="$2"
    local dirname=$(basename "$dir")
    local title
    local index_md

    # Convert dirname to title
    title=$(echo "$dirname" | sed 's/[-_]/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1')

    log "Auto-generating index for $dirname..."

    index_md=$(mktemp)

    # ADD THIS BLOCK HERE:
    cat << EOF > "$index_md"
---
title: $title
show_meta: no
---
EOF
    # Note: Use >> for the rest so we don't overwrite the frontmatter!

    echo "" >> "$index_md"

    # Find all markdown files, extract date, sort, then format into markdown
    find "$dir" -maxdepth 1 -name "*.md" ! -name "index.md" -type f | while read f; do
        file_title=$(extract_title "$f")
        date=$(extract_date "$f")
        slug=$(basename "$f" .md)
        # Output: date|title|slug for sorting
        echo "${date}|${file_title}|${slug}"
    done | sort -r | while IFS='|' read date title slug; do
        if [ -n "$date" ]; then
            echo "* $date [$title]($slug/)" >> "$index_md"
        else
            echo "* [$title]($slug/)" >> "$index_md"
        fi
    done

    # ... (rest of the subdirectory finding logic)

    # Build the page
    build_page "$index_md" "$output"
    rm "$index_md"
}

extract_article_html() {
    sed -n '/<article>/,/<\/article>/ {
        /<header class="post-meta">/,/<\/header>/d
        p
    }' "$1"
}

# Generate blog index
generate_blog_index() {
    local blog_src="$INPUT_DIR/$BLOG_DIR"
    local blog_dst="$OUTPUT_DIR/$BLOG_DIR"
    local index_md

    [ ! -d "$blog_src" ] && return

    log "Generating blog index..."

    index_md=$(mktemp)

    # Use > for the first line to create/clear, then >> for everything else
    echo "---" > "$index_md"
    echo "show_meta: no" >> "$index_md"
    echo "title: Blog" >> "$index_md"
    echo "---" >> "$index_md"
    echo "" >> "$index_md"
    echo "# Blog" >> "$index_md"
    echo "" >> "$index_md"
    echo "[RSS Feed](../feed.xml)" >> "$index_md"
    echo "" >> "$index_md"

    # Find all blog posts, sort by date descending
    find "$blog_src" -name "*.md" ! -name "index.md" | while read f; do
        date=$(extract_date "$f")
        title=$(extract_title "$f")
        slug=$(basename "$f" .md)
        echo "${date}|${title}|${slug}"
    done | sort -r | while IFS='|' read date title slug; do
        if [ "$CLEAN_URLS" = "yes" ]; then
            echo "* $date [$title]($slug/)" >> "$index_md"
        else
            echo "* $date [$title]($slug.html)" >> "$index_md"
        fi
    done

    # Build the index page
    if [ "$CLEAN_URLS" = "yes" ]; then
        build_page "$index_md" "$blog_dst/index.html"
    else
        build_page "$index_md" "$blog_dst.html"
    fi

    rm "$index_md"
}

# Generate RSS feed
generate_rss() {
    local rss_file="$OUTPUT_DIR/feed.xml"
    local blog_src="$INPUT_DIR/$BLOG_DIR"
    
    [ ! -d "$blog_src" ] && return
    [ "$GENERATE_RSS" != "yes" ] && return
    
    log "Generating RSS feed..."
    
    mkdir -p "$(dirname "$rss_file")"
    
    cat > "$rss_file" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<rss 
  version="2.0"
  xmlns:dc="http://purl.org/dc/elements/1.1/">
<channel>
<title>${SITE_TITLE}</title>
<link>${SITE_URL}</link>
<description>${SITE_DESCRIPTION}</description>
<language>en</language>
EOF
    
    # Add items
     find "$blog_src" -name "*.md" ! -name "index.md" | while read f; do
    date=$(extract_date "$f")
    title=$(extract_title "$f")
    slug=$(basename "$f" .md)
    author=$(extract_author "$f")
    [ -z "$author" ] && author="$AUTHOR"


    echo "${date}|${title}|${slug}|${f}"
done | sort -r | head -n 20 | while IFS='|' read date title slug file; do
    if [ "$CLEAN_URLS" = "yes" ]; then
        url="${SITE_URL}/${BLOG_DIR}/${slug}/"
    else
        url="${SITE_URL}/${BLOG_DIR}/${slug}.html"
    fi

    html_file="$OUTPUT_DIR/$BLOG_DIR/$slug/index.html"
    body_html=$(extract_article_html "$html_file")

    cat >> "$rss_file" << EOF
<item>
<title>${title}</title>
<link>${url}</link>
<guid>${url}</guid>
<pubDate>${date}</pubDate>
<dc:creator>${AUTHOR}</dc:creator>
<description><![CDATA[
${body_html}
]]></description>
</item>
EOF
done
   
    echo "</channel>" >> "$rss_file"
    echo "</rss>" >> "$rss_file"
}

# Copy static assets
copy_assets() {
    log "Copying assets..."
    
    for ext in $COPY_EXTENSIONS; do
        find "$INPUT_DIR" -type f -name "*.$ext" | while read f; do
            rel_path=$(echo "$f" | sed "s|^${INPUT_DIR}/||")
            dst="$OUTPUT_DIR/$rel_path"
            
            # Skip if matches ignore pattern
            skip=0
            for pattern in $IGNORE_PATTERNS; do
                if echo "$rel_path" | grep -qE "$pattern"; then
                    skip=1
                    break
                fi
            done
            
            [ $skip -eq 1 ] && continue
            
            mkdir -p "$(dirname "$dst")"
            cp "$f" "$dst"
            log "Copied: $rel_path"
        done
    done
}

# Initialize output directory
init_output() {
    log "Initializing output directory..."
    rm -rf "$OUTPUT_DIR"
    mkdir -p "$OUTPUT_DIR"
}

# Build all pages
build_all() {
    log "Building pages..."
    
    # First, build all existing markdown files
    find "$INPUT_DIR" -type f -name "*.md" | while read f; do
        rel_path=$(echo "$f" | sed "s|^${INPUT_DIR}/||" | sed 's/\.md$//')
        
        # Skip if matches ignore pattern
        skip=0
        for pattern in $IGNORE_PATTERNS; do
            if echo "$rel_path" | grep -qE "$pattern"; then
                skip=1
                break
            fi
        done
        
        [ $skip -eq 1 ] && continue
        
        # Handle index.md files specially (both root and subdirectory)
        if echo "$rel_path" | grep -q '/index$'; then
            # Subdirectory index: blog/index.md -> blog/index.html
            dir_path=$(dirname "$rel_path")
            if [ "$CLEAN_URLS" = "yes" ]; then
                dst="$OUTPUT_DIR/$dir_path/index.html"
            else
                dst="$OUTPUT_DIR/$dir_path.html"
            fi
        elif [ "$rel_path" = "index" ]; then
            # Root index: index.md -> index.html
            dst="$OUTPUT_DIR/index.html"
        elif [ "$CLEAN_URLS" = "yes" ]; then
            dst="$OUTPUT_DIR/$rel_path/index.html"
        else
            dst="$OUTPUT_DIR/$rel_path.html"
        fi
        
        build_page "$f" "$dst"
    done
    
    # Now check for directories that need auto-generated indexes
    find "$INPUT_DIR" -type d ! -path "$INPUT_DIR" | while read dir; do
        rel_dir=$(echo "$dir" | sed "s|^${INPUT_DIR}/||")
        
        # Skip assets directory
        [ "$rel_dir" = "assets" ] && continue
        
        # Skip if matches ignore pattern
        skip=0
        for pattern in $IGNORE_PATTERNS; do
            if echo "$rel_dir" | grep -qE "$pattern"; then
                skip=1
                break
            fi
        done
        
        [ $skip -eq 1 ] && continue
        
        # Check if index.md exists
        if [ ! -f "$dir/index.md" ]; then
            # Generate auto-index
            if [ "$CLEAN_URLS" = "yes" ]; then
                dst="$OUTPUT_DIR/$rel_dir/index.html"
            else
                dst="$OUTPUT_DIR/$rel_dir.html"
            fi
            
            generate_directory_index "$dir" "$dst"
        fi
    done
}

# Main execution
main() {
    # Check for markdown processor
    if ! command -v "$MD_PROCESSOR" > /dev/null 2>&1; then
        error "Markdown processor '$MD_PROCESSOR' not found. Install it or change MD_PROCESSOR in verso.conf"
    fi
    
    # Check templates exist
    if [ ! -f "$TEMPLATE_DIR/header.html" ] || [ ! -f "$TEMPLATE_DIR/footer.html" ]; then
        error "Templates not found in $TEMPLATE_DIR/"
    fi
    
    init_output
    build_all
    copy_assets
    generate_rss
    
    log "Done! Site built in $OUTPUT_DIR/"
}

main
