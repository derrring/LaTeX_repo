% =================================================================
% e_class_noteLong.cls
% A LaTeX class for long-form lecture notes (book-based).
% Version 1.0
% =================================================================

\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{e_class_noteLong}[2026/07/12 v1.0 Lecture notes class]

% --- Class Options (shared prologue: 12pt switch + deprecated cjk/nocjk) ---
\def\e@baseclass{book}
\input{sty_components/e_class_prologue.tex}


\RequirePackage{e_profile_standard}
\RequirePackage{e_frontbackmatter_formal}
\RequirePackage{e_title_fenced_chap}
\RequirePackage{e_math_env_deco}
\RequirePackage{e_heading_scale}

\pagestyle{plain}

% Lecture notes convention: TOC shows chapters + sections + subsections.
% Matches the package default set in c130_toc.tex; stated here explicitly so
% the contrast with e_class_thesis (tocdepth=1) is visible at class level.
\setcounter{tocdepth}{2}

\endinput
