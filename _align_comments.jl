#!/usr/bin/env julia
# align_comments.jl — align trailing `#` comments in contiguous runs of code.
#
# JuliaFormatter (incl. v2.14) has NO option for this: align_assignment only
# moves `=`, align_pair_arrow only `=>`, and comment columns are left as typed.
# This script fills that gap without reformatting anything else.
#
# Usage:
#   julia align_comments.jl FILE             # print aligned text to stdout
#   julia align_comments.jl --write FILE...  # rewrite files in place
#   julia align_comments.jl --gap 3 FILE     # min spaces before `#` (default 2)
#
# Rules:
#   * Only lines that have code AND a trailing `#` comment are touched.
#     Full-line comments, blank lines and code-only lines break a run.
#   * Runs are contiguous lines (no gaps); a lone line is left alone.
#   * `#` inside strings, char literals, backtick commands, `"""…"""` and
#     `#= … =#` block comments is ignored.
#   * For .md/.jmd/.qmd only Julia fenced blocks (```{julia} … ```) are touched,
#     so headings like `# Title` and prose are never rewritten.
#
# Heuristic: a single quote starts a char literal only if a matching `'` exists
# later on the same line; otherwise it is treated as the adjoint operator, so
# `A' # transpose` still aligns.

const MARKDOWN_EXT = (".md", ".jmd", ".qmd")

mutable struct ScanState
    in_triple::Bool
    block_depth::Int
end
ScanState() = ScanState(false, 0)

"""
    trailing_comment(line, st) -> (code, comment) or nothing

Return `(rstrip(code), comment_text)` when the line has code followed by a
single-line `#` comment; `nothing` otherwise. `st` carries multi-line string
and block-comment state across lines.
"""
function trailing_comment(line::AbstractString, st::ScanState)
    n = ncodeunits(line)
    i = 1
    comment_at = 0
    while i <= n
        c = line[i]
        if st.in_triple
            # look for closing """ (an escaped \" is not a closer)
            if startswith(SubString(line, i), "\"\"\"") && !(i > 1 && line[i-1] == '\\')
                st.in_triple = false
                i += 3
            else
                i = nextind(line, i)
            end
            continue
        elseif st.block_depth > 0
            if startswith(SubString(line, i), "#=")
                st.block_depth += 1
                i += 2
            elseif startswith(SubString(line, i), "=#")
                st.block_depth -= 1
                i += 2
            else
                i = nextind(line, i)
            end
            continue
        end

        if c == '"'
            if startswith(SubString(line, i), "\"\"\"")
                st.in_triple = true
                i += 3
            else
                i += 1
                while i <= n
                    if line[i] == '\\'
                        i = i + 1 <= n ? nextind(line, i) : i + 1
                        i = i <= n ? nextind(line, i) : i
                    elseif line[i] == '"'
                        i += 1
                        break
                    else
                        i = nextind(line, i)
                    end
                end
            end
        elseif c == '`'
            i = nextind(line, i)                      # skip the opening backtick
            while i <= n && line[i] != '`'
                escaped = line[i] == '\\' && i < n
                i = escaped ? nextind(line, nextind(line, i)) : nextind(line, i)
            end
            i = i <= n ? nextind(line, i) : i         # skip the closing backtick
        elseif c == '\''
            close_at = findnext('\'', line, nextind(line, i))
            if close_at === nothing
                i = nextind(line, i)          # adjoint
            else
                i = nextind(line, close_at)
            end
        elseif c == '#'
            if startswith(SubString(line, i), "#=")
                st.block_depth += 1
                i += 2
            else
                comment_at = i
                break
            end
        else
            i = nextind(line, i)
        end
    end

    comment_at == 0 && return nothing
    startswith(SubString(line, comment_at), "#=") && return nothing

    code_end = prevind(line, comment_at)
    code_end < 1 && return nothing
    code = rstrip(line[1:code_end])
    isempty(code) && return nothing
    return (code, line[comment_at:end])
end

is_alignable(::Nothing) = false
is_alignable(::Tuple) = true

function align_lines(lines::Vector{String}; gap::Int = 2)
    out = copy(lines)
    st = ScanState()
    run = Int[]
    parts = Tuple{String,String}[]
    changed = 0

    # `parts` holds the (code, comment) split taken while scanning, i.e. with the
    # carried state, so a line whose verdict depends on a `"""` or `#= … =#`
    # spanning earlier lines is never re-scanned out of context here.
    function flush!()
        if length(run) > 1
            width = maximum(textwidth(p[1]) for p in parts) + gap
            for (k, i) in enumerate(run)
                code, comment = parts[k]
                newline = string(code, ' '^(width - textwidth(code)), comment)
                if newline != lines[i]
                    out[i] = newline
                    changed += 1
                end
            end
        end
        empty!(run)
        empty!(parts)
    end

    for (i, raw) in enumerate(lines)
        ts = trailing_comment(chomp(raw), st)
        if st.in_triple || st.block_depth > 0 || ts === nothing
            flush!()
        else
            push!(run, i)
            push!(parts, ts)
        end
    end
    flush!()
    return out, changed
end

md_fence_re = r"^\s*```+\s*\{julia[^}]*\}\s*$"
md_close_re = r"^\s*```+\s*$"

function process_text(text::AbstractString, path::AbstractString; gap::Int = 2)
    is_md = lowercase(splitext(path)[2]) in MARKDOWN_EXT
    # Work on LF internally, then put CRLF back: the split/join below would
    # otherwise drop the '\r' from any line the aligner rewrites.
    crlf = occursin("\r\n", text)
    lines = split(crlf ? replace(text, "\r\n" => "\n") : text, '\n'; keepempty = true)
    out = copy(lines)
    in_julia = false
    block = String[]
    block_idx = Int[]
    changed = 0

    function flush_block!()
        if !isempty(block)
            aligned, c = align_lines(block; gap = gap)
            for (k, i) in enumerate(block_idx)
                out[i] = aligned[k]
            end
            changed += c
            empty!(block); empty!(block_idx)
        end
        return
    end

    for (i, line) in enumerate(lines)
        if is_md
            if in_julia && occursin(md_close_re, line)
                flush_block!()
                in_julia = false
            elseif !in_julia && occursin(md_fence_re, line)
                in_julia = true
            elseif in_julia
                push!(block, line); push!(block_idx, i)
            end
        else
            push!(block, line); push!(block_idx, i)
        end
    end
    flush_block!()
    joined = join(out, '\n')
    return (crlf ? replace(joined, "\n" => "\r\n") : joined), changed
end

function main(args)
    in_place = false
    gap = 2
    files = String[]
    i = 1
    while i <= length(args)
        a = args[i]
        if a == "--write"
            in_place = true
        elseif a == "--gap" && i < length(args)
            i += 1
            gap = parse(Int, args[i])
        elseif a in ("-h", "--help")
            println(read(@__FILE__, String) |> s -> split(s, "# Usage:")[1])
            return 0
        else
            push!(files, a)
        end
        i += 1
    end

    isempty(files) && (println(stderr, "usage: julia align_comments.jl [--write] [--gap N] FILE..."); return 2)

    total = 0
    for f in files
        text = read(f, String)
        newtext, changed = process_text(text, f; gap = gap)
        total += changed
        if in_place
            changed > 0 && Base.write(f, newtext)
            println(stderr, "$f: $changed line(s) realigned")
        else
            print(newtext)
            println(stderr, "$f: $changed line(s) would change")
        end
    end
    return 0
end

if abspath(PROGRAM_FILE) == @__FILE__
    exit(main(ARGS))
end
