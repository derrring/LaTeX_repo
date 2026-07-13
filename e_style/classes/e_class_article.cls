% =================================================================
% e_class_article.cls
% A LaTeX class for articles, based on user-provided style files.
% Version 1.0
% =================================================================

\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{e_class_article}[2026/07/12 v1.0 Article class]

% --- Class Options (shared prologue: 12pt switch + deprecated cjk/nocjk) ---
\def\e@baseclass{article}
\input{sty_components/e_class_prologue.tex}

% --- 2. Load the common style package ---
\RequirePackage{e_profile_standard}
\RequirePackage{e_frontbackmatter_simple}
\RequirePackage{e_heading_scale}

% --- 3. Article-specific Formatting ---
\linespread{1.1}

\endinput
